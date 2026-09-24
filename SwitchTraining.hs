-- | Reproducible training data for the four-switch/two-LED demonstration.
module SwitchTraining (switchSamples, trainSwitches) where

import BrainTrain
import Control.Monad (unless)
import System.Random (mkStdGen, randomRs)

-- Inputs are ordered SW0, SW1, SW2, SW3. Outputs are LED0, LED1.
switchSamples :: [(Vector, Vector)]
switchSamples =
  [ ([a,b,c,d], [max a c, max b d])
  | a <- [0,1], b <- [0,1], c <- [0,1], d <- [0,1] ]

-- Fixed random seed, not manually chosen logic weights.
initialBrain :: Brain
initialBrain =
  let values = take 18 (randomRs (-0.5, 0.5) (mkStdGen 42))
      rows _ [] = []
      rows n xs = take n xs : rows n (drop n xs)
  in [(replicate 3 0.5, rows 3 (take 12 values)),
      (replicate 2 0.5, rows 2 (drop 12 values))]

trainSwitches :: IO ()
trainSwitches = do
  let trained = iterate (learnMany switchSamples) initialBrain !! 20000
      classify = map (>= 0.5)
      correct (input, target) = classify (feed input trained) == classify target
  unless (all correct switchSamples) $
    ioError (userError "Switch training failed: refusing to export incorrect predictions")
  mapM_ (\(input, target) ->
    putStrLn (show input ++ " -> " ++ show (feed input trained)
      ++ " target " ++ show target)) switchSamples
  writeSwitchBrain "BrainClash.template.hs" "SwitchBrain.hs" trained
  putStrLn "Generated SwitchBrain.hs: 16/16 floating-point classifications correct."
  putStrLn "Next: cabal test switch-led-tests (checks actual generated fixed-point inference)."