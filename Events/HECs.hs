module Events.HECs (
    HECs(..),
    Event,
    CapEvent,
    Timestamp,

    eventIndexToTimestamp,
    timestampToEventIndex,
  ) where

import Events.EventTree
import Events.SparkTree
import GHC.RTS.Events

import Data.Array

-----------------------------------------------------------------------------

-- all the data from a .eventlog file
data HECs = HECs {
       hecCount         :: Int,
       hecTrees         :: [(DurationTree, EventTree, SparkTree)],
       hecEventArray    :: Array Int CapEvent,
       hecLastEventTime :: Timestamp,
       maxSparkValue    :: Double,
       maxSparkPool     :: Double,
       durHistogram     :: [(Timestamp, Timestamp)]
     }

-----------------------------------------------------------------------------

eventIndexToTimestamp :: HECs -> Int -> Timestamp
eventIndexToTimestamp HECs{hecEventArray=arr} n =
  time (ce_event (arr ! n))

timestampToEventIndex :: HECs -> Timestamp -> Int
timestampToEventIndex HECs{hecEventArray=arr} ts =
    search l (r+1)
  where
    (l,r) = bounds arr

    search !l !r
      | (r - l) <= 1 = if ts > time (ce_event (arr!l)) then r else l
      | ts < tmid    = search l mid
      | otherwise    = search mid r
      where
        mid  = l + (r - l) `quot` 2
        tmid = time (ce_event (arr!mid))
