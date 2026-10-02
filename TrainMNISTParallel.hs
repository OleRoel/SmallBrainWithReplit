-- | Parallel variant of TrainMNIST: trains a 784 → H → 10 network using
-- model averaging across N cores.
--
-- See TrainMNIST.hs for the sequential single-core version.
--
-- Parallelism strategy: model averaging
-- -------------------------------------
-- Each epoch splits the dataset into N disjoint partitions (one per core)
-- using DuckDB's row_number() % N.  Each partition is trained independently
-- in its own DuckDB process + Haskell thread, then the resulting N models
-- are averaged weight-by-weight.  The total data seen per epoch is still
-- 100% — just processed in parallel.
--
-- Memory model
-- ------------
-- Each worker streams its partition from DuckDB one row at a time via lazy
-- hGetContents, so peak heap per worker is O(network size), not O(data size).
-- 'force' after every weight update prevents thunk accumulation.
--
-- Diagnosing performance
-- ----------------------
--   cabal run train-mnist -- +RTS -s        -- summary (time, GC, alloc)
--   cabal run train-mnist -- +RTS -hT       -- heap profile (needs -prof build)
--   cabal run train-mnist -- +RTS -N4       -- override core count at runtime
--
-- Usage (run from any directory)
-- --------------------------------
--   cabal run train-mnist
--   cabal run train-mnist -- data/mnist_train.parquet 128 5 4
--
-- Positional arguments (all optional)
--   1. path to training Parquet file  (default: <project-root>/data/mnist_train.parquet)
--   2. hidden layer size               (default: 64)
--   3. number of epochs                (default: 5)
--   4. number of parallel workers      (default: all available cores)

module Main where

import BrainTrain
import Control.Concurrent          (setNumCapabilities)
import Control.Concurrent.Async    (mapConcurrently)
import Control.DeepSeq             (force)
import Control.Exception           (evaluate)
import Control.Monad               (foldM)
import Data.List                   (maximumBy)
import Data.Maybe                  (fromMaybe, listToMaybe)
import Data.Ord                    (comparing)
import Data.Time.Clock             (diffUTCTime, getCurrentTime)
import GHC.Conc                    (getNumProcessors)
import Paths_brain                 (getDataDir, getDataFileName)
import System.Environment          (getArgs)
import System.FilePath             ((</>))
import System.IO                   (hClose, hGetContents)
import System.Process              (CreateProcess (..), StdStream (..),
                                    createProcess, proc, waitForProcess)
import Text.Read                   (readMaybe)

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

-- | Open a DuckDB process and return a lazy string of its stdout plus a
-- cleanup action.  The caller must force the string fully before cleanup.
duckdbStream :: String -> IO (String, IO ())
duckdbStream query = do
  (_, Just hout, _, ph) <- createProcess
    (proc "duckdb" (duckdbArgs query)) { std_out = CreatePipe }
  output  <- hGetContents hout
  let cleanup = hClose hout >> waitForProcess ph >> return ()
  return (output, cleanup)

baseSelect :: FilePath -> String
baseSelect path =
  "SELECT label, array_to_string(pixels, ',') FROM '" ++ path ++ "'"

-- ---------------------------------------------------------------------------
-- Data loading
-- ---------------------------------------------------------------------------

-- | Load a small random sample eagerly for use as an accuracy probe.
loadProbe :: FilePath -> Int -> IO [(Vector, Vector)]
loadProbe path n = do
  let query = baseSelect path ++ " USING SAMPLE " ++ show n
  (output, cleanup) <- duckdbStream query
  result <- evaluate $ force $
    map parseSample $ filter (not . null) $ lines output
  cleanup
  return result

-- ---------------------------------------------------------------------------
-- Parallel training
-- ---------------------------------------------------------------------------

-- | Element-wise addition of two layers.
addLayer :: Layer -> Layer -> Layer
addLayer (b1, w1) (b2, w2) =
  ( zipWith (+) b1 b2
  , zipWith (zipWith (+)) w1 w2
  )

-- | Scale all weights and biases in a layer by a scalar.
scaleLayer :: Double -> Layer -> Layer
scaleLayer s (bias, weights) =
  ( map (s *) bias
  , map (map (s *)) weights
  )

-- | Average a list of brains by weight-wise arithmetic mean.
averageBrains :: [Brain] -> Brain
averageBrains []     = error "averageBrains: empty list"
averageBrains [b]    = b
averageBrains brains =
  let n    = fromIntegral (length brains) :: Double
      sums = foldl1 (zipWith addLayer) brains
  in map (scaleLayer (1 / n)) sums

-- | Train on one disjoint partition of the dataset.
-- Partition workerIdx receives the rows where row_number() % nWorkers = workerIdx.
trainWorker :: FilePath -> Int -> Int -> Brain -> IO Brain
trainWorker path workerIdx nWorkers brain = do
  let numbered = "SELECT *, (row_number() OVER ()) - 1 AS rn FROM '" ++ path ++ "'"
      query    = "SELECT label, array_to_string(pixels, ',') "
              ++ "FROM (" ++ numbered ++ ") "
              ++ "WHERE rn % " ++ show nWorkers ++ " = " ++ show workerIdx
              ++ " ORDER BY random()"
  (output, cleanup) <- duckdbStream query
  let samples = map parseSample $ filter (not . null) $ lines output
      -- force (learn …) keeps the brain in normal form after every update,
      -- preventing a thunk chain from accumulating over thousands of steps.
      trained  = foldl' (\b (inp, tgt) -> force (learn inp tgt b)) brain samples
  trained' <- evaluate trained
  cleanup
  return trained'

-- | Run one epoch in parallel: N workers train on disjoint partitions,
-- results are averaged.
parallelEpoch :: FilePath -> Int -> Brain -> IO Brain
parallelEpoch path nWorkers brain = do
  brains <- mapConcurrently
              (\i -> trainWorker path i nWorkers brain)
              [0 .. nWorkers - 1]
  return (averageBrains brains)

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

  -- Auto-detect cores unless overridden by the 4th argument.
  nCores <- maybe getNumProcessors return (nth args 3 >>= readMaybe)
  setNumCapabilities nCores

  putStrLn $ "Training file : " ++ trainPath
  putStrLn   "Loading probe set (1 000 random samples) ..."
  probe <- loadProbe trainPath 1000

  let inputSize = case probe of
                    (pixs, _) : _ -> length pixs
                    []            -> error "train-mnist: probe set is empty"
      arch = [inputSize, hidden, 10]

  putStrLn $ "Architecture  : " ++ show arch
  putStrLn $ "Epochs        : " ++ show nEpochs
  putStrLn $ "Workers       : " ++ show nCores
             ++ " (each trains on 1/" ++ show nCores ++ " of the data, weights averaged)\n"

  brain0 <- newBrain arch
  putStrLn $ "Epoch 0 (untrained)  probe accuracy: " ++ showPct (accuracy probe brain0)

  trained <- foldM
    (\brain epoch -> do
      t0 <- getCurrentTime
      b' <- parallelEpoch trainPath nCores brain
      t1 <- getCurrentTime
      let secs = realToFrac (diffUTCTime t1 t0) :: Double
      putStrLn $ "Epoch " ++ show epoch ++ "/" ++ show nEpochs
              ++ "  accuracy: " ++ showPct (accuracy probe b')
              ++ "  wall: "     ++ showSecs secs
      return b')
    brain0
    [1..nEpochs]

  putStrLn $ "\nFinal probe accuracy : " ++ showPct (accuracy probe trained)
  putStrLn   "Writing BrainClash.hs ..."
  writeBrainClash templatePath "BrainClash.hs" trained
  putStrLn $ "Done — architecture " ++ show arch ++ " written to BrainClash.hs."
