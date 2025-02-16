module Events.ReadEvents (
    registerEventsFromFile, registerEventsFromTrace
  ) where

import Events.EventTree
import Events.SparkTree
import Events.HECs (HECs(..))
import Events.TestEvents
import Events.EventDuration
import qualified GUI.ProgressView as ProgressView
import GUI.ProgressView (ProgressView)

import qualified GHC.RTS.Events as GHCEvents
import GHC.RTS.Events hiding (Event)
import GHC.RTS.Events.Sparks

import Data.Array
import Data.List
import Text.Printf
import System.FilePath
import Control.Monad
import Control.Exception
import qualified Data.Map as Map

-------------------------------------------------------------------------------
-- The GHC.RTS.Events library returns the profile information
-- in a data-streucture which contains a list data structure
-- representing the events i.e. [GHCEvents.Event]
-- ThreadScope transforms this list into an alternative representation
-- which (for each HEC) records event *durations* which are ordered in time.
-- The durations represent the run-lengths for thread execution and
-- run-lengths for garbage colleciton. This data-structure is called
-- EventDuration.
-- ThreadScope then transformations this data-structure into another
-- data-structure which gives a binary-tree view of the event information
-- by performing a binary split on the time domain i.e. the EventTree
-- data structure.

-- GHCEvents.Event => [EventDuration] => EventTree

-------------------------------------------------------------------------------

rawEventsToHECs :: [(Maybe Int, [GHCEvents.Event])] -> Timestamp
                -> [((Double, Double), (DurationTree, EventTree, SparkTree))]
rawEventsToHECs eventList endTime
  = map (toTree . flip lookup heclists)  [0 .. maximum0 (map fst heclists)]
  where
    heclists = [ (h,events) | (Just h,events) <- eventList ]

    toTree Nothing    = ( (0, 0),
                          ( DurationTreeEmpty,
                            EventTree 0 0 (EventTreeLeaf []),
                            emptySparkTree ) )
    toTree (Just evs) =
       ( (maxSparkValue, maxSparkPool),
         ( mkDurationTree (eventsToDurations nondiscrete) endTime,
           mkEventTree discrete endTime,
           mkSparkTree sparkD endTime ) )
       where (discrete, nondiscrete) = partition isDiscreteEvent evs
             ((maxSparkValue, maxSparkPool), sparkD) =
               eventsToSparkDurations nondiscrete

-------------------------------------------------------------------------------

-- XXX: what's this for?
maximum0 :: (Num a, Ord a) => [a] -> a
maximum0 [] = -1
maximum0 x = maximum x

-------------------------------------------------------------------------------

registerEventsFromFile :: String -> ProgressView -> IO (HECs, String, Int, Double)
registerEventsFromFile filename = registerEvents (Left filename)

registerEventsFromTrace :: String -> ProgressView -> IO (HECs, String, Int, Double)
registerEventsFromTrace traceName = registerEvents (Right traceName)

registerEvents :: Either FilePath String
               -> ProgressView
               -> IO (HECs, String, Int, Double)

registerEvents from progress = do

  let msg = case from of
              Left filename -> filename
              Right test    -> test

  ProgressView.setTitle progress ("Loading " ++ takeFileName msg)

  buildEventLog progress from

-------------------------------------------------------------------------------

-- Runs in a background thread
--
buildEventLog :: ProgressView -> Either FilePath String -> IO (HECs, String, Int, Double)
buildEventLog progress from =
  case from of
    Right test     -> build test (testTrace test)
    Left filename  -> do
      stopPulse <- ProgressView.startPulse progress
      fmt <- readEventLogFromFile filename
      stopPulse
      case fmt of
        Left  err -> fail err --FIXME: report error properly
        Right evs -> build filename evs

  where
    build name evs = do
       let
         eventBlockEnd e | EventBlock{ end_time=t } <- spec e = t
         eventBlockEnd e = time e

         lastTx = maximum (0 : map eventBlockEnd (events (dat evs)))

         groups = groupEvents (events (dat evs))
         maxTrees = rawEventsToHECs groups lastTx
         maxSparkValue = maximum (0 : map (fst . fst) maxTrees)
         maxSparkPool = maximum (0 : map (snd . fst) maxTrees)
         trees = map snd maxTrees

         intDoub :: Integral a => a -> Double
         intDoub = fromIntegral

         ilog :: Integral a => a -> a -> a
         ilog b x = floor $ logBase (intDoub b) (intDoub x)

         histo :: Integral a => [a] -> [(a, a)]
         histo xs = Map.toList $ Map.fromListWith (+)
                    $ [(ilog 2 x, x) | x <- xs]

         sparks = sparkInfo (events (dat evs))
         durations = map sparkDuration sparks
         durHistogram = histo durations

         -- sort the events by time and put them in an array
         sorted    = sortGroups groups
         n_events  = length sorted
         event_arr = listArray (0, n_events-1) sorted
         hec_count = length trees

         hecs = HECs {
                  hecCount         = hec_count,
                  hecTrees         = trees,
                  hecEventArray    = event_arr,
                  hecLastEventTime = lastTx,
                  maxSparkValue    = maxSparkValue,
                  maxSparkPool     = maxSparkPool,
                  durHistogram     = durHistogram
               }

         treeProgress :: Int -> (DurationTree, EventTree, SparkTree) -> IO ()
         treeProgress hec (tree1, tree2, tree3) = do
            ProgressView.setText progress $
                     printf "Building HEC %d/%d" (hec+1) hec_count
            ProgressView.setProgress progress hec_count hec
            evaluate tree1
            evaluate (eventTreeMaxDepth tree2)
            evaluate (sparkTreeMaxDepth tree3)
            return ()

       zipWithM_ treeProgress [0..] trees

       --TODO: fully evaluate HECs before returning because othewise the last
       -- bit of work gets done after the progress window has been closed.

       return (hecs, name, n_events, fromIntegral lastTx * 1.0e-9)

-------------------------------------------------------------------------------
