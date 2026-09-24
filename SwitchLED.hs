{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Normalise #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.KnownNat.Solver #-}

module SwitchLED where

import Clash.Prelude
import qualified SwitchBrain as Brain

createDomain vSystem
  { vName = "Board50", vPeriod = 20000, vResetKind = Synchronous }

type DebounceState = (BitVector 4, Index 500000, BitVector 4)

-- Require 500,000 identical samples (10 ms at 50 MHz) before accepting.
-- The entire vector settles together, not independently per bit.
debounceStep :: DebounceState -> BitVector 4 -> (DebounceState, BitVector 4)
debounceStep (candidate, count, accepted) sample =
  let same = sample == candidate
      nextCount = if not same then 1
                  else if count == maxBound then maxBound else count + 1
      settled = same && count == maxBound
      nextAccepted = if settled then sample else accepted
  in ((sample, nextCount, nextAccepted), nextAccepted)

switchInputs :: BitVector 4 -> Vec 4 Brain.Weight
switchInputs switches =
  map (\i -> if testBit switches i then 1 else 0) (0 :> 1 :> 2 :> 3 :> Nil)

-- Actual neural-network inference: no Boolean OR shortcut in the hardware.
networkLEDs :: BitVector 4 -> BitVector 8
networkLEDs switches =
  let outputs = Brain.topEntity (switchInputs switches)
      threshold = $$(fLit (0.5)) :: Brain.Weight
      led0 = outputs !! (0 :: Index 2) >= threshold
      led1 = outputs !! (1 :: Index 2) >= threshold
  in (if led0 then 1 else 0) .|. (if led1 then 2 else 0)

boardCircuit
  :: HiddenClockResetEnable Board50
  => Signal Board50 (BitVector 4)
  -> Signal Board50 (BitVector 8)
boardCircuit switches =
  let synchronized = register 0 (register 0 switches)
      stable = mealy debounceStep (0, 0, 0) synchronized
  in register 0 (networkLEDs <$> stable)

{-# ANN topEntity
  (Synthesize
    { t_name = "switch_led"
    , t_inputs = [PortName "CLOCK_50", PortName "RESET", PortName "SW"]
    , t_output = PortName "LED"
    }) #-}
topEntity
  :: Clock Board50
  -> Reset Board50
  -> Signal Board50 (BitVector 4)
  -> Signal Board50 (BitVector 8)
topEntity clk rst = withClockResetEnable clk rst enableGen boardCircuit