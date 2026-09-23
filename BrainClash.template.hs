{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell  #-}
-- {-# LANGUAGE TypeOperators     #-}

-- | Clash-synthesizable inference core for the 'brain' neural network.
--
-- Only the forward pass is implemented here — training is done offline in
-- Train.hs and the resulting weights are embedded as compile-time constants.
--
-- Synthesise to VHDL:
--   clash --vhdl BrainClash.hs
--
-- Synthesise to Verilog:
--   clash --verilog BrainClash.hs
--
-- The three GHC type-literal plug-ins below are required by clash-prelude.
-- They are pulled in automatically when you build with the brain-clash
-- library stanza in brain.cabal.
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Normalise       #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Extra.Solver    #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.KnownNat.Solver #-}

module BrainClash where

import Clash.Prelude

-- ---------------------------------------------------------------------------
-- Numeric type
-- ---------------------------------------------------------------------------

-- | Fixed-point representation used for all weights and activations.
--
-- @SFixed i f@ is a signed (i + f)-bit number with i integer bits
-- (including the sign bit) and f fractional bits.
--
--   * Range    : [-2^(i-1), 2^(i-1))
--   * Precision: 2^(-f)
--
-- With @SFixed 8 8@ (16-bit):
--   range [-128, 128), precision ≈ 0.004.
--
-- Tune i and f to match your trained weight distribution and area budget.
-- Wider fractional parts improve accuracy; wider integer parts prevent
-- saturation in deep networks or with large inputs.
type Weight = SFixed 8 8

-- ---------------------------------------------------------------------------
-- Layer type
-- ---------------------------------------------------------------------------

-- | A fully-connected layer with fan-in /i/ and fan-out /o/.
--
-- The weight matrix is stored in output-major order: each of the /o/ rows
-- holds the /i/ incoming weights for one output neuron.  This avoids a
-- transpose during the forward pass (compare 'rowTimesMatrix' in LinAlg.hs
-- which stores weights in input-major order and transposes on the fly).
type Layer i o =
  ( Vec o Weight          -- bias vector  (length = fan-out)
  , Vec o (Vec i Weight)  -- weight matrix (o rows × i columns)
  )

-- ---------------------------------------------------------------------------
-- Core operations
-- ---------------------------------------------------------------------------

-- | Fixed-point dot product.
dotP :: KnownNat n => Vec n Weight -> Vec n Weight -> Weight
dotP xs ys = sum (zipWith (*) xs ys)


-- | ReLU activation applied to a single value.
relu :: Weight -> Weight
relu = max 0

-- | Forward pass through one fully-connected layer with ReLU.
--
-- For each output neuron j:
--   output[j] = relu( bias[j] + Σ_i weight[j][i] * input[i] )
layerForward
  :: (KnownNat i, KnownNat o)
  => Vec i Weight  -- ^ input activations
  -> Layer i o     -- ^ (biases, weight matrix)
  -> Vec o Weight
layerForward inputs (biases, weights) =
  map relu $ zipWith (+) biases (map (dotP inputs) weights)

-- ---------------------------------------------------------------------------
-- Trained weights
--
-- Train.hs replaces the block below with fixed-point literals. Do not edit
-- BrainClash.hs directly; edit this template and run `cabal run train`.
-- ---------------------------------------------------------------------------

-- The Train executable replaces the block between these markers after each
-- training run. The block includes the architecture-specific type aliases,
-- forward pass, trained constants, and topEntity signature.
-- GENERATED_WEIGHTS_BEGIN
-- GENERATED_WEIGHTS_END

-- ---------------------------------------------------------------------------
-- Top entity
--
-- This is the hardware boundary Clash synthesizes into a component/module.
-- Ports are plain bit-vectors on the generated HDL side; Clash inserts the
-- fixed-point encoding/decoding automatically.
-- ---------------------------------------------------------------------------

{-# ANN topEntity
  (Synthesize
    { t_name   = "brain_infer"
    , t_inputs = [PortName "input"]
    , t_output = PortName "output"
    }) #-}

-- The generated block above supplies the architecture-specific topEntity
-- signature and forward pass.
