{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
module Main where

import qualified Clash.Prelude as C
import qualified SwitchBrain as Brain
import qualified DE1SoC
import qualified DE1SoCDiagnostic as Diagnostic
import SwitchLED
import Control.Monad (forM_, unless)
import Data.Bits (testBit, (.|.))

check :: String -> Bool -> IO ()
check label ok = do
  unless ok (error ("FAIL: " ++ label))
  putStrLn ("PASS: " ++ label)

main :: IO ()
main = do
  check "diagnostic heartbeat toggles exactly at 25 million clocks"
    (Diagnostic.heartbeatStep (24999998, False) == (24999999, False)
      && Diagnostic.heartbeatStep (24999999, False) == (0, True)
      && Diagnostic.heartbeatStep (24999999, True) == (0, False))
  forM_ [0..15 :: Int] $ \bits -> do
    let switches = fromIntegral bits :: C.BitVector 4
        waveform = C.sampleN @Board50 8 $
          Diagnostic.topEntity C.clockGen (pure False) (pure switches)
    check ("diagnostic switch mirror works while KEY0 held: " ++ show bits)
      (all (== (544 + fromIntegral bits)) (drop 3 waveform))
  let diagnostics = C.sampleN @Board50 500020 $
        Diagnostic.topEntity C.clockGen (pure True) (pure 15)
  check "diagnostic separates input mirror, released key, reset and network LEDs"
    (all (==735) (drop 500010 diagnostics))
  check "diagnostic heartbeat and network-output LED bit placement"
    (Diagnostic.diagnosticLEDs True True False 5 1 == 853
      && Diagnostic.diagnosticLEDs False False True 10 2 == 682)
  let patterns = map fromIntegral [0..15 :: Int] :: [C.BitVector 4]
      pipeline = C.sampleN @Board50 18 $
        C.withClockResetEnable C.clockGen (C.unsafeFromActiveHigh (pure False)) C.enableGen $
          networkCircuit (C.fromList (patterns ++ repeat 0))
  check "pipelined network matches all 16 fixed-point predictions with two-cycle latency"
    (drop 2 pipeline == map networkLEDs patterns)
  forM_ [0..15 :: Int] $ \bits -> do
    let switches = fromIntegral bits :: C.BitVector 4
        expected = (if testBit bits 0 || testBit bits 2 then 1 else 0)
               .|. (if testBit bits 1 || testBit bits 3 then 2 else 0)
                 :: C.BitVector 8
        scores = Brain.topEntity (switchInputs switches)
    check ("switch pattern " ++ show switches ++ ", scores " ++ show scores)
      (networkLEDs switches == expected)
  let (candidate, immediate) = debounceStep (0,0,0) 1
  check "new switch value is not accepted immediately"
    (candidate == (1,1,0) && immediate == 0)
  check "stable switch value accepted after full interval"
    (debounceStep (1,maxBound,0) 1 == ((1,maxBound,1),1))
  check "bounce restarts stability interval"
    (debounceStep (1,499999,0) 2 == ((2,1,0),0))
  let (_, acceptedEarly) = iterate (\(state,_) -> debounceStep state 1)
        ((0,0,0),0) !! 499999
      (_, acceptedOnTime) = iterate (\(state,_) -> debounceStep state 1)
        ((0,0,0),0) !! 500000
  check "debounce accepts exactly at sample 500000"
    (acceptedEarly == 0 && acceptedOnTime == 1)
  let reset = C.unsafeFromActiveHigh
        (C.fromList (True : True : repeat False))
      waveform = C.sampleN @Board50 500020 $
        topEntity C.clockGen reset (pure 15)
  check "reset and debounce keep LEDs off initially"
    (all (==0) (take 500000 waveform))
  check "synchronized, debounced all-on input lights only LED0 and LED1"
    (all (==3) (drop 500010 waveform))
  let boardWave = C.sampleN @Board50 500020 $
        DE1SoC.topEntity C.clockGen (pure True) (pure 15)
  check "DE1-SoC startup reset keeps all ten LEDs off initially"
    (all (==0) (take 500000 boardWave))
  check "DE1-SoC drives LEDR0/1 with LEDR2..9 off"
    (all (==3) (drop 500010 boardWave))
  let pressed = C.sampleN @Board50 20 $
        DE1SoC.topEntity C.clockGen (pure False) (pure 15)
  check "pressed active-low KEY0 holds board in reset"
    (all (==0) pressed)
  let key = C.fromList (replicate 500020 True ++ replicate 10 False ++ repeat True)
      boardResetWave = C.sampleN @Board50 1000050 $
        DE1SoC.topEntity C.clockGen key (pure 15)
  check "KEY0 resets lit LEDs after synchronizer latency"
    (all (==3) (take 5 (drop 500010 boardResetWave))
      && all (==0) (take 10 (drop 500024 boardResetWave)))
  check "release of KEY0 resumes after debounce, not immediately"
    (all (==0) (take 499990 (drop 500034 boardResetWave))
      && all (==3) (drop 1000040 boardResetWave))