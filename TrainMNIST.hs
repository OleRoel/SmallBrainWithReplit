-- | Train a 784 → H → 10 network on MNIST data read from a Parquet file.
--
-- Memory model
-- ------------
-- Rows are streamed from DuckDB one at a time via lazy hGetContents, so
-- peak heap use is proportional to the network size, not the dataset size.
-- Shuffling is delegated to DuckDB (ORDER BY random()) so no in-memory
-- copy of the full dataset is ever needed.
-- 'force' is applied after each weight update to evaluate the new brain
-- to normal form immediately, preventing thunk accumulation over 60 k steps.
--
-- Diagnosing memory use (no recompilation needed)
-- ------------------------------------------------
--   cabal run train-mnist -- +RTS -s        # summary after the run
--   cabal run train-mnist -- +RTS -hT       # heap profile (needs -prof build)
--
-- Usage (run from any directory)
-- --------------------------------
--   cabal run train-mnist
--   cabal run train-mnist -- data/mnist_train.parquet 128 10
--
-- Positional arguments (all optional)
--   1. path to training Parquet file  (default: <project-root>/data/mnist_train.parquet)
--   2. hidden layer size               (default: 64)
--   3. number of epochs                (default: 5)

module Main where

import BrainTrain
import Control.DeepSeq    (force)
import Control.Monad      (foldM)
import Data.List          (maximumBy)
import Data.Maybe         (fromMaybe, listToMaybe)
import Data.Ord           (comparing)
import Paths_brain        (getDataDir, getDataFileName)
import System.Environment (getArgs)
import System.FilePath    ((</>))
import Control.Exception  (evaluate)
import Data.Time.Clock    (getCurrentTime, diffUTCTime)
import System.IO          (hClose, hGetContents)
import System.Process     (CreateProcess (..), StdStream (..),
                           createProcess, proc, waitForProcess)
import Text.Read          (readMaybe)

-- ---------------------------------------------------------------------------
-- Parsing
-- ---------------------------------------------------------------------------

-- | Parse one DuckDB list-mode line: "label|p1,p2,...,p784"
parseSample :: String -> (Vector, Vector)
parseSample line =
  case break (== '|') line of
    (lStr, '|' : pStr) ->
      let lbl    = read lStr :: Int
          pixs   = map read (splitOn ',' pStr) :: [Double]
          target = [ if i == lbl then 1.0 else 0.0 | i <- [0..9] ]
      in (pixs, target)
    _ -> error $ "parseSample: unexpected line: " ++ line

splitOn :: Char -> String -> [String]
splitOn sep = foldr step [""]
  where
    step c (w:ws)
      | c == sep  = "" : w : ws
      | otherwise = (c:w) : ws
    step _ [] = [""]   -- unreachable: seed is non-empty

-- ---------------------------------------------------------------------------
-- DuckDB helpers
-- ---------------------------------------------------------------------------

duckdbArgs :: String -> [String]
duckdbArgs query = ["-list", "-noheader", "-separator", "|", "-c", query]

-- | Open a DuckDB process and return a lazy string of its stdout.
-- The caller is responsible for closing the handle and waiting for the process.
duckdbStream :: String -> IO (String, IO ())
duckdbStream query = do
  (_, Just hout, _, ph) <- createProcess
    (proc "duckdb" (duckdbArgs query)) { std_out = CreatePipe }
  output <- hGetContents hout     -- lazy: rows arrive as they are consumed
  let cleanup = hClose hout >> waitForProcess ph >> return ()
  return (output, cleanup)

-- ---------------------------------------------------------------------------
-- Data loading
-- ---------------------------------------------------------------------------

-- | Load a small random sample eagerly for use as an accuracy probe.
loadProbe :: FilePath -> Int -> IO [(Vector, Vector)]
loadProbe path n = do
  let query = select path ++ " USING SAMPLE " ++ show n
  (output, cleanup) <- duckdbStream query
  let samples = map parseSample $ filter (not . null) $ lines output
  result <- evaluate (force samples)  -- run in IO so handle stays open until done
  cleanup
  return result

-- | Run one training epoch, streaming all rows from DuckDB.
-- DuckDB shuffles with ORDER BY random(); Haskell holds only one sample
-- and the current network in memory at a time.
streamEpoch :: FilePath -> Brain -> IO Brain
streamEpoch path brain = do
  (output, cleanup) <- duckdbStream (select path ++ " ORDER BY random()")
  let samples = map parseSample $ filter (not . null) $ lines output
      -- force (learn …) evaluates the updated brain to NF at every step,
      -- preventing a 60 000-deep thunk chain building up during the fold.
      trained = foldl' (\b (inp, tgt) -> force (learn inp tgt b)) brain samples
  -- evaluate drives foldl' to completion, draining the lazy IO before cleanup.
  trained' <- evaluate trained
  cleanup
  return trained'

select :: FilePath -> String
select path = "SELECT label, array_to_string(pixels, ',') FROM '" ++ path ++ "'"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

classify :: Vector -> Int
classify = fst . maximumBy (comparing snd) . zip [0..]

accuracy :: [(Vector, Vector)] -> Brain -> Double
accuracy samples brain =
  let correct = length $ filter id
        [ classify (feed inp brain) == classify tgt | (inp, tgt) <- samples ]
  in fromIntegral correct / fromIntegral (length samples)

showPct :: Double -> String
showPct x = show (round (x * 100) :: Int) ++ "%"

showSecs :: Double -> String
showSecs s
  | s < 60    = show (round s :: Int) ++ "s"
  | otherwise = show (floor (s / 60) :: Int) ++ "m"
              ++ show (round (s - 60 * fromIntegral (floor (s / 60) :: Int)) :: Int) ++ "s"

nth :: [a] -> Int -> Maybe a
nth []     _ = Nothing
nth (x:_)  0 = Just x
nth (_:xs) n = nth xs (n - 1)

-- ---------------------------------------------------------------------------
-- Main
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  templatePath <- getDataFileName "BrainClash.template"
  dataDir      <- getDataDir
  args         <- getArgs

  let trainPath = fromMaybe (dataDir </> "data" </> "mnist_train.parquet")
                            (listToMaybe args)
      hidden    = fromMaybe 64 $ nth args 1 >>= readMaybe
      nEpochs   = fromMaybe 5  $ nth args 2 >>= (readMaybe :: String -> Maybe Int)

  putStrLn $ "Training file : " ++ trainPath
  putStrLn   "Loading probe set (1 000 random samples) ..."
  probe <- loadProbe trainPath 1000

  let inputSize = case probe of
                    (pixs, _) : _ -> length pixs
                    []            -> error "train-mnist: probe set is empty"
      arch = [inputSize, hidden, 10]

  putStrLn $ "Architecture  : " ++ show arch
  putStrLn $ "Epochs        : " ++ show nEpochs
  putStrLn   "Rows streamed from DuckDB one at a time; shuffled per epoch with ORDER BY random().\n"

  brain0 <- newBrain arch
  putStrLn $ "Epoch 0 (untrained)  probe accuracy: " ++ showPct (accuracy probe brain0)

  trained <- foldM
    (\brain epoch -> do
      t0 <- getCurrentTime
      b' <- streamEpoch trainPath brain
      t1 <- getCurrentTime
      let secs = realToFrac (diffUTCTime t1 t0) :: Double
      putStrLn $ "Epoch " ++ show epoch ++ "/" ++ show nEpochs
              ++ "  accuracy: " ++ showPct (accuracy probe b')
              ++ "  wall: "    ++ showSecs secs
      return b')
    brain0
    [1..nEpochs]

  putStrLn $ "\nFinal probe accuracy : " ++ showPct (accuracy probe trained)
  putStrLn   "Writing BrainClash.hs ..."
  writeBrainClash templatePath "BrainClash.hs" trained
  putStrLn $ "Done — architecture " ++ show arch ++ " written to BrainClash.hs."
