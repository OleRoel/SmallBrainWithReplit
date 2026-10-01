module Main where

import BrainTrain
import Paths_brain (getDataFileName)
import System.Environment (getArgs)
import Text.Read (readMaybe)
import SwitchTraining (trainSwitches)

main :: IO ()
main = do
  templatePath <- getDataFileName "BrainClash.template"
  arguments <- getArgs
  case arguments of
    ["--switch-leds"] -> trainSwitches templatePath
    _ -> trainDemoArguments templatePath arguments

trainDemoArguments :: FilePath -> [String] -> IO ()
trainDemoArguments templatePath arguments = do
  sizes <- either (ioError . userError) pure (parseSizes arguments)
  (input, target, initial, trained) <- trainNetwork sizes
  writeBrainClash templatePath "BrainClash.hs" trained
  putStrLn $ "before: " ++ show (feed input initial)
  putStrLn $ "after:  " ++ show (feed input trained)
  putStrLn $ "target: " ++ show target
  putStrLn $ "generated BrainClash.hs for architecture "
    ++ unwords (map show sizes)

parseSizes :: [String] -> Either String [Int]
parseSizes [] = Right [4, 3, 2]
parseSizes arguments = do
  sizes <- traverse parsePositive arguments
  if length sizes < 2
    then Left "provide at least an input size and one output size"
    else Right sizes

parsePositive :: String -> Either String Int
parsePositive text =
  case readMaybe text of
    Just size
      | size > 0 -> Right size
      | otherwise -> Left ("layer sizes must be positive: " ++ text)
    Nothing -> Left ("not a layer size: " ++ text)