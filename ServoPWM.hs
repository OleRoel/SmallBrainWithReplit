{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
-- createDomain intentionally creates instances for a type-level string.
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.Normalise #-}
{-# OPTIONS_GHC -fplugin GHC.TypeLits.KnownNat.Solver #-}

-- | Provisional hobby-servo timing, NOT a verified D47 hardware configuration.
module ServoPWM where

import Clash.Prelude

-- Clash domain periods are picoseconds: 20,000 ps = 50 MHz.
createDomain vSystem
  { vName = "Servo50", vPeriod = 20000, vResetKind = Synchronous }

type Command = SFixed 8 8
type PulseCycles = Unsigned 20
type FrameCounter = Index 1000000
type PwmState = (FrameCounter, PulseCycles, Bool)

initialState :: PwmState
initialState = (0, 75000, False)

-- | Clamp 0..1 and map to 50,000..100,000 cycles (1..2 ms).
-- Work on the fixed-point representation to avoid synthesized division.
-- Widen before multiplication; the product needs 24 bits.
commandCycles :: Command -> PulseCycles
commandCycles command =
  let raw = unpack (pack command) :: Signed 16
      limited = max 0 (min 256 raw)
      scaled = (fromIntegral limited :: Unsigned 32) * 50000
  in 50000 + resize (shiftR scaled 8)

-- | Latch width/enable only at the frame boundary. Disable takes effect at
-- the next clock; re-enable waits for a boundary rather than resuming a pulse.
pwmStep :: PwmState -> (Bool, PulseCycles) -> (PwmState, Bool)
pwmStep (counter, width, active) (enabled, requested) =
  let atBoundary = counter == 0
      nextWidth = if atBoundary
                    then max 50000 (min 100000 requested)
                    else width
      nextActive = enabled && (atBoundary || active)
      pulseHigh = nextActive && (fromIntegral counter :: PulseCycles) < nextWidth
      nextCounter = if counter == maxBound then 0 else counter + 1
  in ((nextCounter, nextWidth, nextActive), pulseHigh)

-- | Registered output: no combinational counter/comparator glitches at the pin.
-- Reset synchronously clears both state and output. The output register adds
-- one clock of latency without changing pulse width or frame period.
servoPwm
  :: HiddenClockResetEnable Servo50
  => Signal Servo50 Bool
  -> Signal Servo50 Command
  -> Signal Servo50 Bool
servoPwm enabled command =
  register False $
    mealy pwmStep initialState (bundle (enabled, commandCycles <$> command))

{-# ANN topEntity
  (Synthesize
    { t_name = "servo_pwm"
    , t_inputs = [PortName "clk_50", PortName "reset",
                  PortName "servo_enable", PortName "command"]
    , t_output = PortName "servo_pwm_out"
    }) #-}
topEntity
  :: Clock Servo50
  -> Reset Servo50
  -> Signal Servo50 Bool
  -> Signal Servo50 Command
  -> Signal Servo50 Bool
topEntity clk rst = withClockResetEnable clk rst enableGen servoPwm