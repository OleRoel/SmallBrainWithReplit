{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Example integration: output zero controls one servo. No board pin
-- assignments or asynchronous input synchronizers are supplied here.
module BrainServo where

import Clash.Prelude
import qualified BrainClash as Brain
import ServoPWM (Servo50, servoPwm)

{-# ANN topEntity
  (Synthesize
    { t_name = "brain_servo"
    , t_inputs = [PortName "clk_50", PortName "reset",
                  PortName "servo_enable", PortName "network_input"]
    , t_output = PortName "servo_pwm_out"
    }) #-}
topEntity
  :: Clock Servo50
  -> Reset Servo50
  -> Signal Servo50 Bool
  -> Signal Servo50 Brain.BrainInput
  -> Signal Servo50 Bool
topEntity clk rst enabled inputs =
  withClockResetEnable clk rst enableGen $
    servoPwm enabled (head . Brain.topEntity <$> inputs)