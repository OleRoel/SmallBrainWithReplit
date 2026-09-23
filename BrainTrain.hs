{-# LANGUAGE UnicodeSyntax #-}

-- | A minimal feed-forward neural network with ReLU activations,
-- trained by stochastic gradient descent.
--
-- This runnable version keeps the network logic from the imported Gist while
-- using small pure-Haskell vector and matrix operations. That keeps the demo
-- portable and avoids requiring a platform-specific BLAS installation.

module BrainTrain
  ( Vector
  , Matrix
  , Layer
  , Brain
  , newBrain
  , feed
  , learn
  , learnMany
  , trainNetwork
  , trainDemo
  , writeBrainClash
  ) where

import Control.Exception (evaluate)
import Control.Monad (replicateM, zipWithM)
import Data.List     (intercalate, transpose)
import System.Random (randomRIO)
import LinAlg

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

-- | One network layer: bias vector (output size) and
-- weight matrix (input size x output size).
type Layer = (Vector, Matrix)

-- | A network is a list of layers, applied left to right.
type Brain = [Layer]

-- ---------------------------------------------------------------------------
-- Activation function
-- ---------------------------------------------------------------------------

relu :: Vector -> Vector
relu = map (max 0)

-- | Derivative of ReLU (0 for negative input, 1 otherwise)
relu' :: Double -> Double
relu' x
  | x < 0 = 0
  | otherwise = 1

-- ---------------------------------------------------------------------------
-- Network initialisation
-- ---------------------------------------------------------------------------

-- | Draw one sample from a Gaussian distribution with the given
-- standard deviation (Box-Muller transform).
gauss :: Double -> IO Double
gauss stdev = do
  x1 <- randomRIO (1e-12, 1.0)
  x2 <- randomRIO (0.0, 1.0)
  pure $ stdev * sqrt (-2 * log x1) * cos (2 * pi * x2)

-- | A vector of n ones (initial biases)
ones :: Int -> Vector
ones n = replicate n 1

chunksOf :: Int -> [a] -> [[a]]
chunksOf _ [] = []
chunksOf n xs
  | n <= 0 = []
  | otherwise =
      let (chunk, rest) = splitAt n xs
       in chunk : chunksOf n rest

-- | An (m x n) matrix of small Gaussian random values (initial weights)
randomMatrix :: Int -> Int -> IO Matrix
randomMatrix m n = do
  values <- replicateM (m * n) (gauss 0.01)
  pure (chunksOf n values)

-- | Create a network from a list of layer sizes,
-- e.g. @newBrain [784, 30, 10]@ builds two layers: 784→30 and 30→10.
-- Biases start at 1, weights are small Gaussian random values.
newBrain :: [Int] -> IO Brain
newBrain sizes@(_:layerSizes)
  | length sizes < 2 = error "A brain needs an input size and at least one output size"
  | any (<= 0) sizes = error "Brain layer sizes must all be positive"
  | otherwise =
      zip (map ones layerSizes) <$> zipWithM randomMatrix sizes layerSizes
newBrain [] = error "A brain needs an input size and at least one output size"

-- ---------------------------------------------------------------------------
-- Forward pass
-- ---------------------------------------------------------------------------

-- | Weighted input of one layer (before activation):
-- z = inputs × weights + bias
zLayer :: Vector -> Layer -> Vector
zLayer inputs (bias, weights) =
  addVector (rowTimesMatrix inputs weights) bias

-- | Run the network: feed the input through every layer,
-- applying ReLU after each weighted sum.
feed :: Vector -> Brain -> Vector
feed = foldl' (\activation layer -> relu (zLayer activation layer))

-- | Forward pass that keeps intermediate results for backpropagation.
-- Returns (activations, weighted inputs), both newest-first, i.e. output
-- layer at the head. The activations include the input vector (at the tail).
revaz :: Vector -> Brain -> ([Vector], [Vector])
revaz inputs = foldl' step ([inputs], [])
  where
    step (activations@(activation:_), zs) layer =
      let z = zLayer activation layer
       in (relu z : activations, z : zs)
    step ([], zs) _ = ([], zs)

-- ---------------------------------------------------------------------------
-- Backpropagation
-- ---------------------------------------------------------------------------

-- | Compute activations and error deltas for every layer (both in
-- forward order). The delta of the output layer is the cost derivative
-- (activation - expected) times relu'; earlier deltas are propagated
-- backwards through the weight matrices.
deltas :: Vector -> Vector -> Brain -> ([Vector], [Vector])
deltas inputs expected layers =
  case revaz inputs layers of
    (activations@(output:_), outputZ:earlierZs) ->
      let outputDelta = hadamard (subVector output expected) (map relu' outputZ)
       in (reverse activations, backward (map snd (reverse layers)) earlierZs [outputDelta])
    (activations, _) -> (reverse activations, [])
  where
    -- Walk backwards: propagate each delta through its weight matrix.
    backward _ [] deltas' = deltas'
    backward (weights:remainingWeights) (z:remainingZs) deltas'@(delta:_) =
      let propagated = hadamard (matrixTimesVector weights delta) (map relu' z)
       in backward remainingWeights remainingZs (propagated : deltas')
    backward _ _ deltas' = deltas'

-- ---------------------------------------------------------------------------
-- Training
-- ---------------------------------------------------------------------------

-- | Learning rate
eta :: Double
eta = 0.002

-- | Update one layer: subtract the scaled gradients from bias and weights.
-- av is the layer's input activation, dv its delta; the weight gradient
-- is their outer product (input size x output size, matching zLayer).
descend :: Layer -> Vector -> Vector -> Layer
descend (bias, weights) activation delta =
  ( subVector bias (scaleVector eta delta)
  , subMatrix weights (scaleMatrix eta (outer activation delta))
  )

-- | One training step: backpropagate a single sample and update every layer.
learn :: Vector -> Vector -> Brain -> Brain
learn input expected layers =
  let (activations, deltas') = deltas input expected layers
   in zipWith3 descend layers activations deltas'

-- | Train on a list of (input, expected) samples sequentially.
learnMany :: [(Vector, Vector)] -> Brain -> Brain
learnMany samples layers =
  foldl' (\current (input, expected) -> learn input expected current) layers samples


-- ---------------------------------------------------------------------------
-- Clash source generation
-- ---------------------------------------------------------------------------

-- | Convert a trained Double to the numerator used by SFixed 8 8.
fixedScale :: Integer
fixedScale = 256

quantize :: Double -> Integer
quantize value | isNaN value || isInfinite value =
  error "Cannot export a non-finite weight"
quantize value =
  let numerator = round (value * fromIntegral fixedScale)
   in if numerator < -32768 || numerator > 32767
        then error $ "Weight does not fit in SFixed 8 8: " ++ show value
        else numerator

-- | Render a Double as a compile-time Clash fixed-point literal.
showW :: Double -> String
showW value =
  let quantized = fromIntegral (quantize value) / fromIntegral fixedScale
      rendered = show (quantized :: Double)
   in "$$(fLit (" ++ rendered ++ "))"

-- | Render a list of Doubles as a Clash Vec literal.
clashVec :: [Double] -> String
clashVec xs = "(" ++ concatMap (\x -> showW x ++ " :> ") xs ++ "Nil)"

-- | Render a weight matrix as a multi-line Clash Vec-of-Vec literal.
clashMatrix :: [[Double]] -> String
clashMatrix [] = "Nil"
clashMatrix (r:rs) =
  clashVec r
    ++ concatMap (\row -> "\n      :> " ++ clashVec row) rs
    ++ "\n      :> Nil"

-- | Render a layer, transposing input-major training weights into the
-- output-major layout used by BrainClash.
clashLayer :: Layer -> String
clashLayer (bias, weights) =
  "( " ++ clashVec bias ++ "\n"
    ++ "    , " ++ clashMatrix (transpose weights) ++ "\n"
    ++ "    )"

-- | Validate a trained network and return its input/output shape.
networkShape :: Brain -> [Int]
networkShape [] = error "Cannot generate Clash source for an empty brain"
networkShape layers =
  let layerShapes = map layerShape layers
      inputs = map fst layerShapes
      outputs = map snd layerShapes
      shape = firstOf inputs : outputs
   in if and (zipWith (==) (drop 1 inputs) (take (length outputs - 1) outputs))
        then shape
        else error $ "Adjacent brain layers do not match: " ++ show shape
  where
    firstOf (first:_) = first
    firstOf [] = error "Cannot get the first dimension of an empty shape"

    layerShape (bias, weights)
      | null bias || null weights =
          error "Clash generation requires non-empty layers"
      | any ((/= length bias) . length) weights =
          error "Clash generation requires rectangular weight matrices"
      | otherwise = (length weights, length bias)

architectureName :: [Int] -> String
architectureName shape = "Brain" ++ intercalate "_" (map show shape)

layerType :: Int -> Int -> String
layerType inputSize outputSize =
  "Layer " ++ show inputSize ++ " " ++ show outputSize

tupleType :: [String] -> String
tupleType [] = error "Cannot create an empty layer tuple"
tupleType [one] = one
tupleType (firstLayer:remaining) =
  "(" ++ firstLayer ++ ", " ++ tupleType remaining ++ ")"

tupleValue :: [String] -> String
tupleValue [] = error "Cannot create an empty layer value"
tupleValue [one] = one
tupleValue (firstLayer:remaining) =
  "( " ++ firstLayer ++ "\n"
    ++ "  , " ++ tupleValue remaining ++ "\n"
    ++ "  )"

forwardPattern :: [String] -> String
forwardPattern [] = error "Cannot create a forward pattern without layers"
forwardPattern [one] = one
forwardPattern (firstLayer:remaining) =
  "(" ++ firstLayer ++ ", " ++ forwardPattern remaining ++ ")"

forwardBody :: Int -> String
forwardBody layerCount
  | layerCount <= 0 = error "Cannot create a forward body without layers"
  | layerCount == 1 = "  layerForward input l1"
  | otherwise =
      "  let a1 = layerForward input l1\n"
        ++ concatMap activationLine [2 .. layerCount - 1]
        ++ "  in  layerForward a" ++ show (layerCount - 1) ++ " l"
        ++ show layerCount
  where
    activationLine index =
      "      a" ++ show index ++ " = layerForward a"
        ++ show (index - 1) ++ " l" ++ show index ++ "\n"

generatedNetwork :: Brain -> String
generatedNetwork trained =
  let shape = networkShape trained
      inputSize = firstOf shape
      outputSize = lastOf shape
      layerTypes =
        zipWith layerType (take (length shape - 1) shape) (drop 1 shape)
      name = architectureName shape
      layers = map clashLayer trained
      forward =
        "forward :: " ++ name ++ " -> Vec " ++ show inputSize
          ++ " Weight -> Vec " ++ show outputSize ++ " Weight\n"
          ++ "forward " ++ forwardPattern
               ["l" ++ show index | index <- [1 .. length trained]]
          ++ " input =\n"
          ++ forwardBody (length trained)
      trainedValue =
        "trainedBrain :: " ++ name ++ "\n"
          ++ "trainedBrain =\n"
          ++ "  " ++ tupleValue layers
      top =
        "topEntity :: Vec " ++ show inputSize ++ " Weight -> Vec "
          ++ show outputSize ++ " Weight\n"
          ++ "topEntity = BrainClash.forward trainedBrain"
   in "-- Generated architecture and weights. Do not edit this block.\n"
        ++ "type " ++ name ++ " = " ++ tupleType layerTypes ++ "\n\n"
        ++ "type BrainInput = Vec " ++ show inputSize ++ " Weight\n\n"
        ++ forward ++ "\n\n"
        ++ trainedValue ++ "\n\n"
        ++ top
  where
    firstOf (first:_) = first
    firstOf [] = error "Generated brain shape is empty"

    lastOf [] = error "Generated brain shape is empty"
    lastOf values = firstOf (reverse values)

generatedBegin :: String
generatedBegin = "-- GENERATED_WEIGHTS_BEGIN"

generatedEnd :: String
generatedEnd = "-- GENERATED_WEIGHTS_END"

replaceGeneratedBlock :: String -> String -> String
replaceGeneratedBlock source replacement =
  case break (== generatedBegin) (lines source) of
    (before, _:afterBegin) ->
      case break (== generatedEnd) afterBegin of
        (_, _:afterEnd) ->
          unlines
            ( before
                ++ [generatedBegin]
                ++ lines replacement
                ++ [generatedEnd]
                ++ afterEnd
            )
        _ -> error "BrainClash template is missing GENERATED_WEIGHTS_END"
    _ -> error "BrainClash template is missing GENERATED_WEIGHTS_BEGIN"

-- | Generate a complete BrainClash.hs from the hand-written template.
writeBrainClash :: FilePath -> FilePath -> Brain -> IO ()
writeBrainClash templatePath outputPath trained = do
  template <- readFile templatePath
  let source = replaceGeneratedBlock template (generatedNetwork trained)
  -- Validate the complete output before opening the existing file for writing.
  _ <- evaluate (length source)
  writeFile outputPath source

-- | Create and train a network for the single-sample demo.
trainNetwork :: [Int] -> IO (Vector, Vector, Brain, Brain)
trainNetwork sizes = do
  initial <- newBrain sizes
  let inputSize = case sizes of
        size:_ -> size
        [] -> error "A brain needs an input size"
      outputSize = case reverse sizes of
        output:_ -> output
        [] -> error "A brain needs an output size"
      input = [1 .. fromIntegral inputSize]
      target = 1 : replicate (outputSize - 1) 0
      trained = iterate (learn input target) initial !! 100
  pure (input, target, initial, trained)

-- | Create the default 4 → 3 → 2 demo network.
trainDemo :: IO (Vector, Vector, Brain, Brain)
trainDemo = trainNetwork [4, 3, 2]
