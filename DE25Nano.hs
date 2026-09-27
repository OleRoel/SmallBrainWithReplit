{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Terasic DE25-Nano boundary. Reuse the trained DE1-SoC network unchanged;
-- the new board has eight FPGA-controlled LEDs rather than ten.
module DE25Nano where

import Clash.Prelude
import qualified DE1SoC
import SwitchLED (Board50)

{-# ANN topEntity
  (Synthesize
    { t_name = "de25_nano"
    , t_inputs = [PortName "CLOCK1_50", PortName "KEY0", PortName "SW"]
    , t_output = PortName "LEDR"
    }) #-}
topEntity
  :: Clock Board50
  -> Signal Board50 Bool
  -> Signal Board50 (BitVector 4)
  -> Signal Board50 (BitVector 8)
topEntity clk key0 switches =
  slice d7 d0 <$> DE1SoC.topEntity clk key0 switches