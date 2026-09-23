module Main where

import BrainTrain

main :: IO ()
main = do
  (input, target, initial, trained) <- trainDemo
  writeBrainClash "BrainClash.template.hs" "BrainClash.hs" trained
  putStrLn $ "before: " ++ show (feed input initial)
  putStrLn $ "after:  " ++ show (feed input trained)
  putStrLn $ "target: " ++ show target
  putStrLn "generated BrainClash.hs"