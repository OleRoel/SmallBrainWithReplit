#!/usr/bin/env cabal
{- cabal:
  build-depends: base >= 4, containers, vector, hmatrix, random
-}

{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UnicodeSyntax #-}

-- | A minimal feed-forward neural network with ReLU activations,
-- trained by stochastic gradient descent.
--
-- Network layout: weights are stored as (input x output) matrices,
-- so the forward pass is @inputs <# weights + bias@.

import Numeric.LinearAlgebra
import System.Random
import Control.Monad

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

-- | One network layer: bias vector (output size) and
-- weight matrix (input size x output size).
type Layer = (Vector Double, Matrix Double)

-- | A network is a list of layers, applied left to right.
type Brain = [Layer]

-- ---------------------------------------------------------------------------
-- Unicode linear algebra operators
-- ---------------------------------------------------------------------------

-- | Scaling by a scalar: 0x22C5 DOT OPERATOR ⋅
class Scaling a b c | a b -> c where
  infixl 7 ⋅
  (⋅) :: a -> b -> c

instance (Num t) => Scaling t t t where
  (⋅) = (*)

instance (Container Vector t) => Scaling t (Vector t) (Vector t) where
  (⋅) = scale

instance (Container Vector t) => Scaling (Vector t) t (Vector t) where
  (⋅) = flip scale

instance (Num t, Container Vector t) => Scaling t (Matrix t) (Matrix t) where
  (⋅) = scale

instance (Num t, Container Vector t) => Scaling (Matrix t) t (Matrix t) where
  (⋅) = flip scale

-- | Contraction (dot product, matrix-vector and matrix-matrix product):
-- 0x00D7 MULTIPLICATION SIGN ×
class Mul a b c | a b -> c, a c -> b, b c -> a where
  infixl 7 ×
  (×) :: a -> b -> c

instance (Product t) => Mul (Vector t) (Vector t) t where
  (×) = udot

instance (Numeric t, Product t) => Mul (Matrix t) (Vector t) (Vector t) where
  (×) = (#>)

instance (Numeric t, Product t) => Mul (Vector t) (Matrix t) (Vector t) where
  (×) = (<#)

instance (Numeric t, Product t) => Mul (Matrix t) (Matrix t) (Matrix t) where
  (×) = (Numeric.LinearAlgebra.<>)

-- ---------------------------------------------------------------------------
-- Activation function
-- ---------------------------------------------------------------------------

-- | Rectified linear unit, applied element-wise to a vector
relu :: Vector Double -> Vector Double
relu = cmap (max 0)

-- | Derivative of ReLU (0 for negative input, 1 otherwise)
relu' :: Double -> Double
relu' x | x < 0     = 0
        | otherwise = 1

-- ---------------------------------------------------------------------------
-- Network initialisation
-- ---------------------------------------------------------------------------

-- | Draw one sample from a Gaussian distribution with the given
-- standard deviation (Box-Muller transform)
gauss :: Double -> IO Double
gauss stdev = do
  x1 <- randomIO
  x2 <- randomIO
  return $ stdev * sqrt (-2 * log x1) * cos (2 * pi * x2)

-- | A vector of n ones (initial biases)
ones :: Int -> Vector Double
ones = konst 1

-- | An (m x n) matrix of small Gaussian random values (initial weights)
randomMatrix :: Int -> Int -> IO (Matrix Double)
randomMatrix m n = (m >< n) <$> replicateM (m * n) (gauss 0.01)

-- | Create a network from a list of layer sizes,
-- e.g. @newBrain [784, 30, 10]@ builds two layers: 784→30 and 30→10.
-- Biases start at 1, weights are small Gaussian random values.
newBrain :: [Int] -> IO Brain
newBrain szs@(_:ts) = zip (ones <$> ts) <$> zipWithM randomMatrix szs ts
newBrain []         = return []

-- ---------------------------------------------------------------------------
-- Forward pass
-- ---------------------------------------------------------------------------

-- | Weighted input of one layer (before activation):
-- z = inputs × weights + bias
zLayer :: Vector Double -> Layer -> Vector Double
zLayer inputs (bias, weights) = inputs × weights + bias

-- | Run the network: feed the input through every layer,
-- applying ReLU after each weighted sum
feed :: Vector Double -> Brain -> Vector Double
feed = foldl' ((relu .) . zLayer)

-- | Forward pass that keeps intermediate results for backpropagation.
-- Returns (activations, weighted inputs), both newest-first, i.e. output
-- layer at the head. The activations include the input vector (at the tail).
revaz :: Vector Double -> Brain -> ([Vector Double], [Vector Double])
revaz inputs = foldl' step ([inputs], [])
  where
    step (avs@(av:_), zs) layer =
        let z = zLayer av layer
        in  (relu z : avs, z : zs)

-- ---------------------------------------------------------------------------
-- Backpropagation
-- ---------------------------------------------------------------------------

-- | Compute activations and error deltas for every layer (both in
-- forward order). The delta of the output layer is the cost derivative
-- (activation - expected) times relu'; earlier deltas are propagated
-- backwards through the weight matrices.
deltas :: Vector Double -> Vector Double -> Brain -> ([Vector Double], [Vector Double])
deltas inputs expected layers =
    let (avs@(av:_), zv:zvs) = revaz inputs layers
        delta0 = (av - expected) * cmap relu' zv
    in  (reverse avs, backward (snd <$> reverse layers) zvs [delta0])
  where
    -- Walk backwards: propagate each delta through its weight matrix
    backward _ [] dvs = dvs
    backward (wm:wms) (zv:zvs) dvs@(dv:_) =
        backward wms zvs $ (wm × dv) * cmap relu' zv : dvs

-- ---------------------------------------------------------------------------
-- Training
-- ---------------------------------------------------------------------------

-- | Learning rate
eta :: Double
eta = 0.002

-- | Update one layer: subtract the scaled gradients from bias and weights.
-- av is the layer's input activation, dv its delta; the weight gradient
-- is their outer product (input size x output size, matching zLayer).
descend :: Layer -> Vector Double -> Vector Double -> Layer
descend (b, w) av dv = (b - eta ⋅ dv, w - eta ⋅ outer av dv)

-- | One training step: backpropagate a single sample and update every layer
learn :: Vector Double -> Vector Double -> Brain -> Brain
learn xv yv layers =
    let (avs, dvs) = deltas xv yv layers
    in  zipWith3 descend layers avs dvs

-- | Train on a list of (input, expected) samples sequentially
learnMany :: [(Vector Double, Vector Double)] -> Brain -> Brain
learnMany samples layers = foldl' (\lys (xv, yv) -> learn xv yv lys) layers samples

-- ---------------------------------------------------------------------------
-- Demo
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  brain <- newBrain [4, 3, 2]
  let xv      = vector [1, 2, 3, 4]
      yv      = vector [1, 0]
      trained = iterate (learn xv yv) brain !! 100
  putStrLn $ "before: " ++ show (feed xv brain)
  putStrLn $ "after:  " ++ show (feed xv trained)
  putStrLn $ "target: " ++ show yv
