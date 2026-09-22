{-# LANGUAGE UnicodeSyntax #-}

-- | A minimal feed-forward neural network with ReLU activations,
-- trained by stochastic gradient descent.
--
-- This runnable version keeps the network logic from the imported Gist while
-- using small pure-Haskell vector and matrix operations. That keeps the demo
-- portable and avoids requiring a platform-specific BLAS installation.

import Control.Monad (replicateM, zipWithM)
import Data.List     (transpose)
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
newBrain sizes@(_:layerSizes) =
  zip (map ones layerSizes) <$> zipWithM randomMatrix sizes layerSizes
newBrain [] = pure []

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
{--
learnMany :: [(Vector, Vector)] -> Brain -> Brain
learnMany samples layers =
  foldl' (\current (input, expected) -> learn input expected current) layers samples
--}


-- ---------------------------------------------------------------------------
-- Weight export – Clash Vec literal format
-- ---------------------------------------------------------------------------

-- | Render a Double safely for embedding in a Clash Vec literal.
-- Negative values are parenthesised to prevent (:>) being mis-parsed as
-- binary subtraction, e.g. @a :> -1.0 :> Nil@ → @a :> (-1.0) :> Nil@.
showW :: Double -> String
showW x
  | x < 0    = "(" ++ show x ++ ")"
  | otherwise = show x

-- | Render a list of Doubles as a Clash Vec literal: @(a :> b :> c :> Nil)@
clashVec :: [Double] -> String
clashVec xs = "(" ++ concatMap (\x -> showW x ++ " :> ") xs ++ "Nil)"

-- | Render a weight matrix as a multi-line Clash Vec-of-Vec literal.
-- Each row sits on its own line; continuation @:>@ lines are indented to
-- align with the opening parenthesis of the first row.
clashMatrix :: [[Double]] -> String
clashMatrix []     = "Nil"
clashMatrix (r:rs) = clashVec r
  ++ concatMap (\row -> "\n      :> " ++ clashVec row) rs
  ++ "\n      :> Nil"

-- | Render a Layer as a Clash @(biases, weights)@ tuple literal.
-- The weight matrix is transposed from brain.hs's input-major storage
-- (weights[input][output]) to BrainClash's output-major storage
-- (weights[output][input], one row per output neuron).
clashLayer :: Layer -> String
clashLayer (bias, weights) =
     "( " ++ clashVec bias ++ "\n"
  ++ "    , " ++ clashMatrix (transpose weights) ++ "\n"
  ++ "    )"

-- | Print a complete @trainedBrain@ binding ready to paste into BrainClash.hs.
printClashWeights :: Brain -> IO ()
printClashWeights [l1, l2] = putStrLn $
     "-- Paste into BrainClash.hs, replacing trainedBrain:\n"
  ++ "trainedBrain :: Brain4_3_2\n"
  ++ "trainedBrain =\n"
  ++ "  ( " ++ clashLayer l1 ++ "\n"
  ++ "  , " ++ clashLayer l2 ++ "\n"
  ++ "  )"
printClashWeights _ =
  putStrLn "-- printClashWeights: expected exactly 2 layers"

-- ---------------------------------------------------------------------------
-- Demo
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  brain <- newBrain [4, 3, 2]
  let input = [1, 2, 3, 4]
      target = [1, 0]
      trained = iterate (learn input target) brain !! 100
  putStrLn $ "before: " ++ show (feed input brain)
  putStrLn $ "after:  " ++ show (feed input trained)
  putStrLn $ "target: " ++ show target
  putStrLn ""
  printClashWeights trained
