-- | Pure-Haskell vector and matrix operations used by the neural network.
module LinAlg
  ( Vector
  , Matrix
  , dot
  , addVector
  , subVector
  , hadamard
  , scaleVector
  , scaleMatrix
  , outer
  , rowTimesMatrix
  , matrixTimesVector
  , subMatrix
  ) where

import Data.List (transpose)

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

type Vector = [Double]
type Matrix = [[Double]]

-- ---------------------------------------------------------------------------
-- Vector operations
-- ---------------------------------------------------------------------------

dot :: Vector -> Vector -> Double
dot xs ys = sum (zipWith (*) xs ys)

addVector :: Vector -> Vector -> Vector
addVector = zipWith (+)

subVector :: Vector -> Vector -> Vector
subVector = zipWith (-)

-- | Element-wise product (Hadamard product).
hadamard :: Vector -> Vector -> Vector
hadamard = zipWith (*)

scaleVector :: Double -> Vector -> Vector
scaleVector scalar = map (scalar *)

-- ---------------------------------------------------------------------------
-- Matrix operations
-- ---------------------------------------------------------------------------

scaleMatrix :: Double -> Matrix -> Matrix
scaleMatrix scalar = map (scaleVector scalar)

-- | Outer product: produces a matrix from two vectors.
outer :: Vector -> Vector -> Matrix
outer xs ys = map (`scaleVector` ys) xs

-- | Row-vector times matrix. The matrix is stored as input rows by output
-- columns, matching the layout used in the original Gist.
rowTimesMatrix :: Vector -> Matrix -> Vector
rowTimesMatrix inputs weights =
  map (dot inputs) (transpose weights)

-- | Matrix times column-vector.
matrixTimesVector :: Matrix -> Vector -> Vector
matrixTimesVector matrix values =
  map (`dot` values) matrix

subMatrix :: Matrix -> Matrix -> Matrix
subMatrix = zipWith (zipWith (-))
