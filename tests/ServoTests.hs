{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Control.Monad (unless)
import qualified Clash.Prelude as C
import ServoPWM

check :: String -> Bool -> IO ()
check label passed = do
  unless passed (error label)
  putStrLn ("PASS: " ++ label)

-- Count a complete frame using the actual synthesizable state transition.
frame :: PulseCycles -> (PwmState, Int)
frame width = foldl' step (initialState, 0) [1..1000000 :: Int]
  where
    step (state, count) _ =
      let (next, high) = pwmStep state (True, width)
          nextCount = count + if high then 1 else 0
      in nextCount `seq` next `seq` (next, nextCount)

main :: IO ()
main = do
  check "negative commands clamp to 1 ms" (commandCycles (-1) == 50000)
  check "zero maps to 1 ms" (commandCycles 0 == 50000)
  check "half scale maps to 1.5 ms" (commandCycles 0.5 == 75000)
  check "one maps to 2 ms" (commandCycles 1 == 100000)
  check "large commands clamp to 2 ms" (commandCycles 127 == 100000)
  mapM_ (\width -> do
    let ((counter, _, active), highs) = frame width
    check ("frame width " ++ show width)
      (highs == fromIntegral width && counter == 0 && active))
    [50000, 75000, 100000]
  let ((_, heldWidth, _), heldHigh) =
        pwmStep (60000, 100000, True) (True, 50000)
  check "mid-frame command cannot shorten current pulse"
    (heldWidth == 100000 && heldHigh)
  check "pulse ends at latched width"
    (not (snd (pwmStep (100000, 100000, True) (True, 100000))))
  let (disabled, disableHigh) = pwmStep (100, 100000, True) (False, 100000)
      (_, reenableHigh) = pwmStep disabled (True, 100000)
  check "disable cuts pulse; re-enable does not resume it"
    (not disableHigh && not reenableHigh)
  check "next boundary accepts new width and enable"
    (pwmStep (0, 100000, False) (True, 50000) == ((1, 50000, True), True))
  let reset = C.unsafeFromActiveHigh (pure True)
      heldReset = C.sampleN @Servo50 10 $
        topEntity C.clockGen reset (pure True) (pure 0.5)
  check "asserted reset keeps registered output low" (not (or heldReset))
  let noReset = C.unsafeFromActiveHigh (pure False)
      off = C.sampleN @Servo50 10 $
        topEntity C.clockGen noReset (pure False) (pure 0.5)
  check "disabled signal stays low" (not (or off))
  let releasedReset = C.unsafeFromActiveHigh
        (C.fromList (True : True : repeat False))
      startup = C.sampleN @Servo50 5 $
        topEntity C.clockGen releasedReset (pure True) (pure 0.5)
  check "reset release starts a new registered pulse"
    (startup == [False, False, False, True, True])
  let waveform = C.sampleN @Servo50 1000003 $
        topEntity C.clockGen releasedReset (pure True) (pure 0.5)
      firstFrame = take 1000000 (drop 3 waveform)
  check "registered output has exactly 75000 high clocks in one frame"
    (length (filter id firstFrame) == 75000)
  check "registered output has one contiguous pulse, then stays low"
    (and (take 75000 firstFrame) && not (or (drop 75000 firstFrame)))