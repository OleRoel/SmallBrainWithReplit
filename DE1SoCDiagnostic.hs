{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators #-}

-- | Independent board indicators: KEY0 cannot stop the heartbeat or switch LEDs.
module DE1SoCDiagnostic where

import Clash.Prelude
import qualified DE1SoC
import SwitchLED (Board50)

heartbeatStep
  :: (Index 25000000, Bool)
  -> (Index 25000000, Bool)
heartbeatStep (count, on)
  | count == maxBound = (0, not on)
  | otherwise = (count + 1, on)

diagnosticLEDs
  :: Bool -> Bool -> Bool -> BitVector 4 -> BitVector 10 -> BitVector 10
diagnosticLEDs heartbeat keyReleased resetActive switches network =
  (1 :: BitVector 1) ++# (boolToBV heartbeat :: BitVector 1)
    ++# slice d1 d0 network
    ++# (boolToBV resetActive :: BitVector 1)
    ++# (boolToBV keyReleased :: BitVector 1) ++# switches

{-# ANN topEntity
  (Synthesize
    { t_name = "de1_soc_diagnostic"
    , t_inputs = [PortName "CLOCK_50", PortName "KEY0", PortName "SW"]
    , t_output = PortName "LEDR"
    }) #-}
topEntity
  :: Clock Board50
  -> Signal Board50 Bool
  -> Signal Board50 (BitVector 4)
  -> Signal Board50 (BitVector 10)
topEntity clk key0 switches =
  let noReset = unsafeFromActiveHigh (pure False)
      (heartbeat, keyReleased, synchronized) =
        withClockResetEnable clk noReset enableGen $
          let counter = register (0, False) (heartbeatStep <$> counter)
          in (snd <$> counter,
              register True (register True key0),
              register 0 (register 0 switches))
      resetActive = unsafeToActiveHigh (DE1SoC.buttonReset clk key0)
      network = DE1SoC.topEntity clk key0 switches
  in diagnosticLEDs <$> heartbeat <*> keyReleased <*> resetActive
       <*> synchronized <*> network