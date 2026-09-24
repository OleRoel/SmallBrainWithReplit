{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

-- | DE1-SoC board boundary; network weights and debounce logic are unchanged.
module DE1SoC where

import Clash.Prelude
import SwitchLED (Board50)
import qualified SwitchLED

-- | KEY0 is low when pressed. Two unreset synchronizer stages start asserted,
-- providing a startup reset as well as synchronous assertion/release.
buttonReset :: Clock Board50 -> Signal Board50 Bool -> Reset Board50
buttonReset clk key0 =
  let noReset = unsafeFromActiveHigh (pure False)
      synced = withClockResetEnable clk noReset enableGen $
        register True (register True (not <$> key0))
  in unsafeFromActiveHigh synced

{-# ANN topEntity
  (Synthesize
    { t_name = "de1_soc"
    , t_inputs = [PortName "CLOCK_50", PortName "KEY0", PortName "SW"]
    , t_output = PortName "LEDR"
    }) #-}
topEntity
  :: Clock Board50
  -> Signal Board50 Bool
  -> Signal Board50 (BitVector 4)
  -> Signal Board50 (BitVector 10)
topEntity clk key0 switches =
  zeroExtend <$> SwitchLED.topEntity clk (buttonReset clk key0) switches