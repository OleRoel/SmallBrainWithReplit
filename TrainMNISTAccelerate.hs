{-# LANGUAGE TypeOperators       #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | Train a 784 → H → 10 network on MNIST data using Accelerate for
-- GPU/CPU-parallel mini-batch stochastic gradient descent.
--
-- Structural differences from TrainMNIST.hs
-- ------------------------------------------
-- TrainMNIST.hs   : sequential SGD, one sample at a time, [Double] lists
-- This file        : mini-batch SGD, B samples at once, Accelerate arrays
--
-- Memory model
-- ------------
-- Mini-batches are collected from the DuckDB stream (B rows at a time).
-- Each batch is loaded into Accelerate arrays, processed, then discarded.
-- Peak heap ≈ B × inputSize floats + network weights.
--
-- Backend selection: change the ONE import below.
--   import Data.Array.Accelerate.LLVM.Native  as Run  -- CPU via LLVM (default)
--   import Data.Array.Accelerate.LLVM.PTX     as Run  -- NVIDIA GPU via CUDA
--   import Data.Array.Accelerate.Interpreter  as Run  -- pure Haskell (slow)
--
-- Usage (run from any directory)
-- --------------------------------
--   cabal run train-mnist-accelerate
--   cabal run train-mnist-accelerate -- data/mnist_train.parquet 128 5 256 0.01
--
-- Positional arguments (all optional)
--   1. path to training Parquet file  (default: <project-root>/data/mnist_train.parquet)
--   2. hidden layer size               (default: 64)
--   3. number of epochs                (default: 5)
--   4. mini-batch size                 (default: 256)
--   5. learning rate                   (default: 0.01)

module Main where

-- BrainTrain is used only for weight export (writeBrainClash).
import qualified BrainTrain                         as BT

import           Control.DeepSeq                    (force)
import           Control.Exception                  (evaluate)
import           Control.Monad                      (foldM, replicateM)
import           Data.List                          (transpose)
import           Data.Maybe                         (fromMaybe, listToMaybe)
import           Data.Time.Clock                    (diffUTCTime, getCurrentTime)
import           Paths_brain                        (getDataDir, getDataFileName)
import           System.Environment                 (getArgs)
import           System.FilePath                    ((</>))
import           System.IO                          (hClose, hGetContents)
import           System.Process                     ( CreateProcess (..)
                                                    , StdStream (..)
                                                    , createProcess, proc
                                                    , waitForProcess )
import           System.Random                      (randomRIO)
import           Text.Read                          (readMaybe)

import qualified Data.Array.Accelerate              as A
import           Data.Array.Accelerate              ( Array, DIM1, DIM2
                                                    , Z (..), (:.) (..)
                                                    , Exp )
import qualified Data.Array.Accelerate.LLVM.Native  as Run

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

type Weight  = Float

-- | A layer stored as Accelerate arrays.
-- Weights are in output-major order (outputSize × inputSize):
-- each row holds the fan-in weights for one output neuron.
-- This matches the BrainClash.hs layout.
type AccLayer = ( Array DIM1 Weight   -- biases  (outputSize)
                , Array DIM2 Weight   -- weights (outputSize × inputSize)
                )

type AccBrain = [AccLayer]

-- ---------------------------------------------------------------------------
-- Matrix operations (Acc DSL)
--
-- matMulABT a b  =  a @ b^T    shapes: (m×k) × (n×k) → (m×n)
-- matMulAB  a b  =  a @ b      shapes: (m×k) × (k×n) → (m×n)
-- matMulATB a b  =  a^T @ b    shapes: (k×m) × (k×n) → (m×n)
-- ---------------------------------------------------------------------------

-- | a @ b^T — used in the forward pass: batchInput @ weights^T
-- result[i,j] = Σ_l  a[i,l] × b[j,l]
matMulABT :: A.Acc (Array DIM2 Weight)
          -> A.Acc (Array DIM2 Weight)
          -> A.Acc (Array DIM2 Weight)
matMulABT a b =
  let (Z :. m :. _) = A.unlift (A.shape a) :: Z :. Exp Int :. Exp Int
      (Z :. n :. _) = A.unlift (A.shape b) :: Z :. Exp Int :. Exp Int
  in A.fold (+) 0
   $ A.zipWith (*)
       (A.replicate (A.lift $ Z :. A.All :. n :. A.All) a)
       (A.replicate (A.lift $ Z :. m :. A.All :. A.All) b)

-- | a @ b — used in backward pass: delta @ weights
matMulAB :: A.Acc (Array DIM2 Weight)
         -> A.Acc (Array DIM2 Weight)
         -> A.Acc (Array DIM2 Weight)
matMulAB a b = matMulABT a (A.transpose b)

-- | a^T @ b — used for weight gradients: delta^T @ activations
matMulATB :: A.Acc (Array DIM2 Weight)
          -> A.Acc (Array DIM2 Weight)
          -> A.Acc (Array DIM2 Weight)
matMulATB a = matMulAB (A.transpose a)

-- ---------------------------------------------------------------------------
-- Batch neural-network primitives (Acc DSL)
-- ---------------------------------------------------------------------------

-- | ReLU applied element-wise to a batch matrix.
batchReLU :: A.Acc (Array DIM2 Weight) -> A.Acc (Array DIM2 Weight)
batchReLU = A.map (A.max 0)

-- | Element-wise derivative of ReLU: 1 where z > 0, else 0.
batchReLUGrad :: A.Acc (Array DIM2 Weight) -> A.Acc (Array DIM2 Weight)
batchReLUGrad = A.map (\x -> A.cond (x A.> 0) 1 0)

-- | Broadcast a bias vector across all rows of a batch matrix.
-- mat: (N × out), bias: (out,) → (N × out)
addBias :: A.Acc (Array DIM2 Weight)
        -> A.Acc (Array DIM1 Weight)
        -> A.Acc (Array DIM2 Weight)
addBias mat bias =
  let (Z :. n :. _) = A.unlift (A.shape mat) :: Z :. Exp Int :. Exp Int
  in A.zipWith (+) mat (A.replicate (A.lift $ Z :. n :. A.All) bias)

-- ---------------------------------------------------------------------------
-- Forward pass
-- ---------------------------------------------------------------------------

-- | Run one layer on a batch; returns (pre-activation z, activation a).
batchLayerForward :: AccLayer -> Array DIM2 Weight
                  -> (Array DIM2 Weight, Array DIM2 Weight)
batchLayerForward (biases, weights) input = Run.run $
  let z = addBias (matMulABT (A.use input) (A.use weights)) (A.use biases)
      a = batchReLU z
  in A.lift (z, a)

-- | Full forward pass through all layers.
-- Returns (zs, activations) where activations[0] = input, activations[k] = output of layer k.
-- zs[k] = pre-activation of layer k.  Both lists are in forward order.
batchForward :: AccBrain -> Array DIM2 Weight
             -> ([Array DIM2 Weight], [Array DIM2 Weight])
batchForward layers input = go layers input [] [input]
  where
    go []     _   zAcc aAcc = (reverse zAcc, reverse aAcc)
    go (l:ls) act zAcc aAcc =
      let (z, a) = batchLayerForward l act
      in go ls a (z : zAcc) (a : aAcc)

-- ---------------------------------------------------------------------------
-- Backward pass
-- ---------------------------------------------------------------------------

-- | Output layer delta: (prediction − target) ⊙ relu'(z_out).
-- Shapes: predictions (N × out), targets (N × out), z_out (N × out).
outputDelta :: Array DIM2 Weight -> Array DIM2 Weight -> Array DIM2 Weight
            -> Array DIM2 Weight
outputDelta preds targets z = Run.run $
  A.zipWith (*) (A.zipWith (-) (A.use preds) (A.use targets))
                (batchReLUGrad (A.use z))

-- | Propagate delta backwards through one layer.
-- delta (N × outSize), weights (outSize × inSize), z (N × inSize) → (N × inSize)
hiddenDelta :: Array DIM2 Weight -> Array DIM2 Weight -> Array DIM2 Weight
            -> Array DIM2 Weight
hiddenDelta delta weights z = Run.run $
  A.zipWith (*) (matMulAB (A.use delta) (A.use weights))
                (batchReLUGrad (A.use z))

-- | Average gradient for one layer's biases and weights.
-- delta (N × out), layerInput (N × in)
-- → (grad_bias (out), grad_weight (out × in))
layerGradients :: Array DIM2 Weight -> Array DIM2 Weight
               -> (Array DIM1 Weight, Array DIM2 Weight)
layerGradients delta layerInput = Run.run $
  let n     = A.indexHead (A.indexTail (A.shape (A.use delta)))
      invN  = 1 A./ A.fromIntegral n
      gradW = A.map (* invN) (matMulATB (A.use delta) (A.use layerInput))
      gradB = A.map (* invN) (A.fold (+) 0 (A.transpose (A.use delta)))
  in A.lift (gradB, gradW)

-- ---------------------------------------------------------------------------
-- Weight update
-- ---------------------------------------------------------------------------

applyGradW :: Float -> Array DIM1 Weight -> Array DIM2 Weight
           -> Array DIM2 Weight -> Array DIM1 Weight
           -> AccLayer
applyGradW eta gB gW weights biases = Run.run $
  let eta'     = A.constant eta
      weights' = A.zipWith (\g w -> w - eta' * g) (A.use gW) (A.use weights)
      biases'  = A.zipWith (\g b -> b - eta' * g) (A.use gB) (A.use biases)
  in A.lift (biases', weights')

-- ---------------------------------------------------------------------------
-- Brain strictness
-- ---------------------------------------------------------------------------

-- | Force every AccLayer in the brain to WHNF.
--
-- trainBatch returns 'zipWith3 updateOne …' which is a LAZY list.
-- With foldl', only the first cons cell (first layer) is forced per step.
-- The second layer accumulates as a 235-deep thunk chain that retains
-- every batch's intermediate arrays (zs, activations, deltas).
-- strictBrain breaks the chain by forcing all Run.run calls up front.
strictBrain :: AccBrain -> AccBrain
strictBrain [] = []
strictBrain ((b, w) : rest) =
  let rest' = strictBrain rest   -- force all subsequent layers first
  in b `seq` w `seq` rest' `seq` ((b, w) : rest')

-- ---------------------------------------------------------------------------
-- One mini-batch training step
-- ---------------------------------------------------------------------------

trainBatch :: Float -> AccBrain -> Array DIM2 Weight -> Array DIM2 Weight -> AccBrain
trainBatch eta brain inputArr targetArr =
  let (zs, activations) = batchForward brain inputArr
      -- activations : [input, A1, A2, …]  length = numLayers + 1
      -- zs          : [Z1, Z2, …]          length = numLayers

      -- Compute output delta
      dOut = outputDelta (last activations) targetArr (last zs)

      -- Backpropagate through hidden layers (reversed).
      -- revNextLayers : layers whose weights we use to propagate the delta
      --                 = layers 2..L in reverse (tail reversed)
      revNextLayers = reverse (tail brain)
      revHiddenZs   = tail (reverse zs)
      hiddenDeltas  = scanl backpropOne dOut (zip revNextLayers revHiddenZs)

      -- hiddenDeltas : [dOut, d_{L-1}, …, d_1]  (output-first)
      -- Reverse to get deltas in forward layer order
      allDeltas = reverse hiddenDeltas           -- [d_1, …, d_{L-1}, dOut]
      layerInputs = init activations             -- [input, A1, …]  (inputs to each layer)

  in zipWith3 updateOne brain allDeltas layerInputs
  where
    backpropOne prevDelta (layer, z) =
      let (_, w) = layer in hiddenDelta prevDelta w z

    updateOne (biases, weights) delta layerInput =
      let (gB, gW) = layerGradients delta layerInput
      in applyGradW eta gB gW weights biases

-- ---------------------------------------------------------------------------
-- Data loading (same DuckDB approach as TrainMNIST.hs)
-- ---------------------------------------------------------------------------

parseSample :: String -> ([Float], [Float])
parseSample line =
  case break (== '|') line of
    (lStr, '|' : pStr) ->
      let lbl    = read lStr :: Int
          pixs   = map read (splitOn ',' pStr) :: [Float]
          target = [ if i == lbl then 1.0 else 0.0 | i <- [0..9] ]
      in (pixs, target)
    _ -> error $ "parseSample: unexpected line: " ++ line

splitOn :: Char -> String -> [String]
splitOn sep = foldr step [""]
  where
    step c (w:ws)
      | c == sep  = "" : w : ws
      | otherwise = (c:w) : ws
    step _ [] = [""]

duckdbStream :: String -> IO (String, IO ())
duckdbStream query = do
  (_, Just hout, _, ph) <- createProcess
    (proc "duckdb" ["-list", "-noheader", "-separator", "|", "-c", query])
    { std_out = CreatePipe }
  output  <- hGetContents hout
  let cleanup = hClose hout >> waitForProcess ph >> return ()
  return (output, cleanup)

baseSelect :: FilePath -> String
baseSelect path = "SELECT label, array_to_string(pixels, ',') FROM '" ++ path ++ "'"

-- | Load a small random probe set eagerly.
loadProbe :: FilePath -> Int -> IO [([Float], [Float])]
loadProbe path n = do
  let query = baseSelect path ++ " USING SAMPLE " ++ show n
  (output, cleanup) <- duckdbStream query
  -- force (not just evaluate) is required: evaluate only forces WHNF (one
  -- element), leaving the remaining 999 lines unread from the handle.
  -- force drives the entire list to normal form before cleanup closes it.
  result <- evaluate $ force $ map parseSample $ filter (not . null) $ lines output
  cleanup
  return result

-- | Split a list into chunks of at most n elements.
chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs = let (h, t) = splitAt n xs in h : chunksOf n t

-- | Convert a list of samples into an Accelerate batch matrix pair.
toBatchArrays :: [([Float], [Float])] -> (Array DIM2 Float, Array DIM2 Float)
toBatchArrays batch =
  let b       = length batch
      inSize  = length (fst (head batch))
      outSize = length (snd (head batch))
      xFlat   = concatMap fst batch
      yFlat   = concatMap snd batch
  in ( A.fromList (Z :. b :. inSize)  xFlat
     , A.fromList (Z :. b :. outSize) yFlat )

-- ---------------------------------------------------------------------------
-- Epoch training (streaming mini-batches from DuckDB)
-- ---------------------------------------------------------------------------

streamEpoch :: FilePath -> Int -> Float -> AccBrain -> IO AccBrain
streamEpoch path batchSize eta brain = do
  let query = baseSelect path ++ " ORDER BY random()"
  (output, cleanup) <- duckdbStream query
  let rows    = filter (not . null) (lines output)
      samples = map parseSample rows
      batches = chunksOf batchSize samples
  -- foldl' (strict) forces the accumulator at each step, ensuring every
  -- batch is consumed from the stream before cleanup closes the handle.
  trained <- evaluate $ foldl' trainOneBatch brain batches
  cleanup
  return trained
  where
    trainOneBatch b batch
      | null batch = b
      | otherwise  =
          let (xArr, yArr) = toBatchArrays batch
          in strictBrain (trainBatch eta b xArr yArr)

-- ---------------------------------------------------------------------------
-- Accuracy (on a pre-loaded probe set)
-- ---------------------------------------------------------------------------

-- | Run the entire probe set through the network in ONE batched forward pass.
-- This avoids 1000 separate Run.run calls and lets Accelerate amortise
-- kernel launch overhead across all samples at once.
probeAccuracy :: AccBrain -> [([Float], [Float])] -> Double
probeAccuracy _     []      = 0
probeAccuracy brain samples =
  let b         = length samples
      inSize    = length (fst (head samples))
      xArr      = A.fromList (Z :. b :. inSize) (concatMap fst samples)
      (_, acts) = batchForward brain xArr
      -- last acts: (b × 10) scores, flattened row-major
      scoreRows = chunksOf 10 (A.toList (last acts))
      targets   = map (argmaxL . snd) samples
      preds     = map argmaxL scoreRows
      correct   = length (filter id (zipWith (==) preds targets))
  in fromIntegral correct / fromIntegral b
  where
    argmaxL xs = fst $ foldl1 pick (zip [0 :: Int ..] xs)
    pick a@(_, u) b'@(_, v) = if v > u then b' else a

-- ---------------------------------------------------------------------------
-- Weight initialisation
-- ---------------------------------------------------------------------------

gaussFloat :: Float -> IO Float
gaussFloat stdev = do
  x1 <- randomRIO (1e-12 :: Float, 1.0)
  x2 <- randomRIO (0.0   :: Float, 1.0)
  return $ stdev * sqrt (-2 * log x1) * cos (2 * pi * x2)

newAccLayer :: Int -> Int -> IO AccLayer
newAccLayer inputSize outputSize = do
  ws <- replicateM (outputSize * inputSize) (gaussFloat 0.01)
  let bs = replicate outputSize 0.1
  return ( A.fromList (Z :. outputSize) bs
         , A.fromList (Z :. outputSize :. inputSize) ws )

newAccBrain :: [Int] -> IO AccBrain
newAccBrain sizes = mapM (uncurry newAccLayer) (zip sizes (tail sizes))

-- ---------------------------------------------------------------------------
-- Export — convert AccBrain to BrainTrain.Brain for writeBrainClash
-- ---------------------------------------------------------------------------

-- | Convert one AccLayer to a BrainTrain.Layer.
-- AccLayer weights are (outputSize × inputSize) — output-major.
-- BrainTrain.Layer weights are (inputSize × outputSize) — input-major.
-- writeBrainClash then re-transposes to output-major for BrainClash.hs,
-- so we must supply input-major here.
accLayerToBT :: AccLayer -> BT.Layer
accLayerToBT (biases, weights) =
  let bs  = map realToFrac (A.toList biases) :: [Double]
      Z :. outSize :. inSize = A.arrayShape weights
      -- Flat list in row-major order: [w[0,0], w[0,1], …, w[out-1,in-1]]
      -- where w[j,k] = weight from input k to output j (output-major)
      wFlat  = map realToFrac (A.toList weights) :: [Double]
      wRows  = chunksOfN inSize wFlat            -- outSize rows, each inSize long
      -- Transpose to input-major: each row = all output-weights for one input
      wInput = transpose wRows
      _ = (outSize, inSize)
  in (bs, wInput)

chunksOfN :: Int -> [a] -> [[a]]
chunksOfN _ [] = []
chunksOfN n xs = let (h, t) = splitAt n xs in h : chunksOfN n t

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

showPct :: Double -> String
showPct x = show (round (x * 100) :: Int) ++ "%"

showSecs :: Double -> String
showSecs s
  | s < 60    = show (round s :: Int) ++ "s"
  | otherwise = show (floor (s / 60) :: Int) ++ "m"
              ++ show (round (s - 60 * fromIntegral (floor (s / 60) :: Int)) :: Int) ++ "s"

nth :: [a] -> Int -> Maybe a
nth []     _ = Nothing
nth (x:_)  0 = Just x
nth (_:xs) n = nth xs (n - 1)

-- ---------------------------------------------------------------------------
-- Main
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  templatePath <- getDataFileName "BrainClash.template"
  dataDir      <- getDataDir
  args         <- getArgs

  let trainPath  = fromMaybe (dataDir </> "data" </> "mnist_train.parquet")
                             (listToMaybe args)
      hidden     = fromMaybe 64    $ nth args 1 >>= readMaybe
      nEpochs    = fromMaybe 5     $ nth args 2 >>= (readMaybe :: String -> Maybe Int)
      batchSize  = fromMaybe 256   $ nth args 3 >>= readMaybe
      eta        = fromMaybe 0.01  $ nth args 4 >>= (readMaybe :: String -> Maybe Float)

  putStrLn $ "Training file : " ++ trainPath
  putStrLn   "Loading probe set (1 000 random samples) ..."
  probe <- loadProbe trainPath 1000

  let inputSize = case probe of { (p, _) : _ -> length p; [] -> error "empty probe" }
      arch      = [inputSize, hidden, 10]

  putStrLn $ "Architecture  : " ++ show arch
  putStrLn $ "Epochs        : " ++ show nEpochs
  putStrLn $ "Batch size    : " ++ show batchSize
  putStrLn $ "Learning rate : " ++ show eta
  putStrLn   "Mini-batch SGD via Accelerate (CPU LLVM backend by default).\n"

  brain0 <- newAccBrain arch
  putStrLn $ "Epoch 0 (untrained)  probe accuracy: "
          ++ showPct (probeAccuracy brain0 probe)

  trained <- foldM
    (\brain epoch -> do
      t0 <- getCurrentTime
      b' <- streamEpoch trainPath batchSize eta brain
      t1 <- getCurrentTime
      let secs = realToFrac (diffUTCTime t1 t0) :: Double
      putStrLn $ "Epoch " ++ show epoch ++ "/" ++ show nEpochs
              ++ "  accuracy: " ++ showPct (probeAccuracy b' probe)
              ++ "  wall: "     ++ showSecs secs
      return b')
    brain0
    [1..nEpochs]

  putStrLn $ "\nFinal probe accuracy : " ++ showPct (probeAccuracy trained probe)
  putStrLn   "Writing BrainClash.hs ..."
  BT.writeBrainClash templatePath "BrainClash.hs" (map accLayerToBT trained)
  putStrLn $ "Done — architecture " ++ show arch ++ " written to BrainClash.hs."
