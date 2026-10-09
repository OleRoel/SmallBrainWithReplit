{-# LANGUAGE TypeOperators #-}

-- | Accelerate-based inference core — the software complement to BrainClash.hs.
--
-- Execution targets
-- -----------------
--   BrainClash.hs      → Clash synthesizes to VHDL/Verilog → FPGA bitstream
--   BrainAccelerate.hs → Accelerate JIT-compiles to LLVM  → CPU or GPU
--
-- Backend selection: change the ONE import line below.
--
--   import Data.Array.Accelerate.LLVM.Native  as Run  -- CPU via LLVM (default)
--   import Data.Array.Accelerate.LLVM.PTX     as Run  -- NVIDIA GPU via CUDA
--   import Data.Array.Accelerate.Interpreter  as Run  -- pure Haskell (slow, no LLVM)
--
-- Weight format
-- -------------
-- Weights are stored as plain 'Float' Haskell lists and converted via
-- 'layerFromLists'.  To populate from a trained network:
--
--   1. Run  cabal run train-mnist  (or train)  to generate BrainClash.hs.
--   2. Copy the numeric values from the $$(fLit (x)) literals in BrainClash.hs,
--      stripping the Template Haskell wrapper, and paste them into
--      'trainedLayer1' / 'trainedLayer2' below.
--
-- Example: $$(fLit (0.9296875)) :> ... :> Nil  →  [0.9296875, ...]
--
-- Alternatively, extend BrainTrain.writeBrainClash to also write a
-- BrainAccelerate.hs using the same float-literal format used by clashVec.

module Main where

import qualified Data.Array.Accelerate              as A
import           Data.Array.Accelerate              ( Array, DIM1, DIM2
                                                    , Z(..), (:.)(..) )
import qualified Data.Array.Accelerate.LLVM.Native  as Run

-- ---------------------------------------------------------------------------
-- Weight type
-- ---------------------------------------------------------------------------

-- | 32-bit float — matches the precision level of SFixed 8 8 in BrainClash.hs
-- and the Float stored in the Parquet training data.
type Weight = Float

-- ---------------------------------------------------------------------------
-- Layer representation
-- ---------------------------------------------------------------------------

-- | A fully-connected layer: (biases, weight matrix).
-- The weight matrix has shape (outputSize × inputSize): each row holds the
-- fan-in weights for one output neuron.  This matches the output-major layout
-- used in BrainClash.hs (type Layer i o = (Vec o Weight, Vec o (Vec i Weight))).
type Layer = ( Array DIM1 Weight   -- bias vector   (length = outputSize)
             , Array DIM2 Weight   -- weight matrix (outputSize × inputSize)
             )

-- ---------------------------------------------------------------------------
-- Core operations (expressed in the Acc DSL; fused by the backend)
-- ---------------------------------------------------------------------------

-- | Matrix-vector multiply:  W (outputSize × inputSize)  ×  x (inputSize)
-- Each element of the result is the dot product of one row of W with x.
matVec :: A.Acc (Array DIM2 Weight)
       -> A.Acc (Array DIM1 Weight)
       -> A.Acc (Array DIM1 Weight)
matVec mat vec =
  A.fold (+) 0 $
  A.generate (A.shape mat) $ \ix ->
    let j = A.indexHead ix        -- column = input index
    in mat A.! ix * vec A.! A.index1 j

-- | ReLU activation: max(0, x) applied element-wise.
relu :: A.Acc (Array DIM1 Weight) -> A.Acc (Array DIM1 Weight)
relu = A.map (A.max 0)

-- | Forward pass through one fully-connected layer with ReLU:
--   output[j] = relu( bias[j] + Σ_i weights[j,i] * input[i] )
layerForward :: A.Acc (Array DIM2 Weight)   -- weight matrix (out × in)
             -> A.Acc (Array DIM1 Weight)   -- bias vector   (out)
             -> A.Acc (Array DIM1 Weight)   -- input         (in)
             -> A.Acc (Array DIM1 Weight)   -- output        (out) after ReLU
layerForward weights biases input =
  relu $ A.zipWith (+) biases (matVec weights input)

-- ---------------------------------------------------------------------------
-- Multi-layer forward pass
-- ---------------------------------------------------------------------------

-- | Build the full inference pipeline as a single fused Acc expression.
-- All layers are chained before Run.run is called, so the backend can
-- fuse and optimise the entire computation in one pass.
forwardAcc :: [Layer] -> A.Acc (Array DIM1 Weight) -> A.Acc (Array DIM1 Weight)
forwardAcc layers input = foldl step input layers
  where
    step acc (biases, weights) = layerForward (A.use weights) (A.use biases) acc

-- | Execute inference on the configured backend.
infer :: [Layer] -> Array DIM1 Weight -> Array DIM1 Weight
infer network input = Run.run $ forwardAcc network (A.use input)

-- ---------------------------------------------------------------------------
-- Weight construction helpers
-- ---------------------------------------------------------------------------

-- | Build a Layer from plain Haskell lists.
--
-- @
-- layerFromLists
--   [b0, b1, ..., b_{o-1}]          -- o biases
--   [[w00, w01, ..., w0_{i-1}],      -- weights for output neuron 0
--    [w10, w11, ..., w1_{i-1}],      -- weights for output neuron 1
--    ...]                            -- o rows in total
-- @
layerFromLists :: [Weight]    -- ^ biases     (length = outputSize)
               -> [[Weight]]  -- ^ weight rows (outputSize rows, each inputSize long)
               -> Layer
layerFromLists biases weightRows =
  let outputSize = length biases
      inputSize  = case weightRows of { (r:_) -> length r; [] -> 0 }
  in ( A.fromList (Z :. outputSize) biases
     , A.fromList (Z :. outputSize :. inputSize) (concat weightRows)
     )

-- | All-zero layer — used as a placeholder until real weights are pasted in.
zeroLayer :: Int   -- ^ inputSize
          -> Int   -- ^ outputSize
          -> Layer
zeroLayer inputSize outputSize =
  layerFromLists
    (replicate outputSize 0)
    (replicate outputSize (replicate inputSize 0))

-- ---------------------------------------------------------------------------
-- Trained weights
--
-- Paste the numeric values from BrainClash.hs here.
-- Each $$(fLit (x)) entry in BrainClash.hs corresponds to one Float.
--
-- Layer 1 bias: the Vec 64 Weight line that starts trainedBrain
-- Layer 1 weights: the 784-element rows that follow (one row per output neuron)
-- Layer 2 bias / weights: same pattern for the second layer
-- ---------------------------------------------------------------------------

-- | Replace with the bias vector from the first layer of trainedBrain.
trainedBiases1 :: [Weight]
trainedBiases1 = replicate 64 0  -- placeholder: 64 zeros

-- | Replace with the weight rows from the first layer of trainedBrain.
-- Each inner list has 784 elements (one per input pixel).
-- There are 64 rows (one per hidden neuron).
trainedWeights1 :: [[Weight]]
trainedWeights1 = replicate 64 (replicate 784 0)  -- placeholder

-- | Replace with the bias vector from the second layer of trainedBrain.
trainedBiases2 :: [Weight]
trainedBiases2 = replicate 10 0  -- placeholder: 10 zeros

-- | Replace with the weight rows from the second layer of trainedBrain.
-- Each inner list has 64 elements (one per hidden neuron).
-- There are 10 rows (one per output class).
trainedWeights2 :: [[Weight]]
trainedWeights2 = replicate 10 (replicate 64 0)  -- placeholder

-- | The complete trained network, assembled from the weight lists above.
trainedNetwork :: [Layer]
trainedNetwork =
  [ layerFromLists trainedBiases1 trainedWeights1   -- 784 → 64
  , layerFromLists trainedBiases2 trainedWeights2   -- 64  → 10
  ]

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  putStrLn "BrainAccelerate — Accelerate-based MNIST inference"
  putStrLn "Architecture: 784 → 64 → 10"
  putStrLn ""

  -- Test with a mid-grey image: all pixels at 0.5, within the normalised
  -- [0.01, ~1.01] range produced by convert_parquet.sql.
  let inputSize = 784
      testInput = A.fromList (Z :. inputSize) (replicate inputSize 0.5 :: [Weight])
      scores    = A.toList (infer trainedNetwork testInput)
      predicted = argmax scores

  putStrLn $ "Test input   : " ++ show inputSize ++ " pixels (constant 0.5)"
  putStrLn $ "Output scores: " ++ show scores
  putStrLn $ "Predicted    : digit " ++ show predicted
  putStrLn ""
  putStrLn "Note: scores are zero because trainedNetwork uses placeholder weights."
  putStrLn "To see real results, paste the weight values from BrainClash.hs"
  putStrLn "into trainedBiases1 / trainedWeights1 / trainedBiases2 / trainedWeights2."

-- | Index of the largest element — the network's class prediction.
argmax :: (Ord a) => [a] -> Int
argmax [] = error "argmax: empty list"
argmax xs = fst $ foldl1 pick (zip [0..] xs)
  where pick a@(_, u) b@(_, v) = if v > u then b else a
