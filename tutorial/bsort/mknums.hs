-------------------------------------------------------------------------------
--- $Id: BSort.hs#1 2009/03/06 10:53:15 REDMOND\\satnams $
-------------------------------------------------------------------------------

module Main
where

import System.Random

main :: IO ()
main 
  = do nums <- sequence (replicate (2^14) (getStdRandom (randomR (1,255))))
       let _ = nums :: [Int]
       writeFile "nums" (unwords (map show nums))
