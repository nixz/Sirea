-- some tests for behaviors.
{-# LANGUAGE TypeOperators #-}
module Main 
    ( main 
    ) where

import Sirea.Prelude
import Sirea.UnsafeIO
import Sirea.Clock
import Sirea.Time
import Control.Monad (unless)

-- assertions
assertb :: String -> (a -> Bool) -> B (S P0 a) (S P0 a)
assertb tstName test = bvoid $ bfmap test >>> unsafeOnUpdateB mkAssert
    where mkAssert _ = return doAssert
          doAssert _ b = 
            if b then putStrLn ("PASS: " ++ tstName)
                 else ioError $ userError ("FAIL: " ++ tstName)

-- test for dead code due to binl or binr - shouldn't even create bcx.
assertDeadOnInput :: String -> B (S P0 x) (S P0 x)
assertDeadOnInput msg = bvoid $ bconst () >>> unsafeOnUpdateB mkAssert
    where mkAssert _ = ioError (userError ("FAIL: " ++ msg)) >> undefined

-- test for dead code on output. This requires a lazy assertion, otherwise
-- the assertion itself would keep the behavior alive for output. 
assertDeadOnOutput :: String -> B (S P0 ()) (S P0 ())
assertDeadOnOutput msg = bconst () >>> unsafeOnUpdateBL mkAssert
    where mkAssert _ = ioError (userError ("FAIL: " ++ msg)) >> undefined


tstConst = bvoid $ bconst 42 >>> assertb "tstConst" (== 42)
tstFmap  = bvoid $ bconst 7 >>> bfmap (* 6) >>> assertb "tstFmap" (== 42)
tstZip   = bvoid $ (bconst 7 &&& bconst 6) >>> bzipWith (*) >>> assertb "tstZip" (== 42)
tstSwap  = bvoid $ bdup >>> (bconst 7 *** bconst 6) >>> bswap >>> (assertb "tstSwap1" (== 6) *** assertb "tstSwap2" (== 7))
tstSplitL = bvoid $ bconst (Left 7) >>> bsplit >>> (assertb "tstSplitL" (== 7) +++ assertb "tstSplitL" (== 6))
tstSplitR = bvoid $ bconst (Right 6) >>> bsplit >>> (assertb "tstSplitR" (== 7) +++ assertb "tstSplitR" (== 6))
tstInL = bvoid $ binl >>> bright (assertDeadOnInput "tstInL lives in R") >>> bleft (assertb "tstInL" (== ()))
tstInR = bvoid $ binr >>> bleft (assertDeadOnInput "tstInR lives in L") >>> bright (assertb "tstInR" (== ()))
tstDeadOutput = bvoid (assertDeadOnOutput "tstDeadOutput lives") >>> assertb "tstDeadOutput" (== ())

tstDisjoinL = bvoid $ (bconst (Left 7) &&& bconst 6) 
                >>> bfirst bsplit -- ((Int :|: Int) :&: Int)
                >>> bdisjoinrz 
                >>> (bzipWith (*) +++ bzipWith (*))
                >>> (assertb "tstDisjoinL" (== 42) +++ assertb "tstDisjoinL in R?" (const False))

tstDisjoinR = bvoid $ (bconst (Right 7) &&& bconst 6) 
                >>> bfirst bsplit 
                >>> bdisjoinrz 
                >>> (bzipWith (*) +++ bzipWith (*))
                >>> (assertb "tstDisjoinR in L?" (const False) +++ assertb "tstDisjoinR" (== 42))

--tstFail = bvoid $ assertb "tstFail" (const False)

tstAssocp = bvoid $ bdup >>> bsecond bdup >>> (bconst 7 *** (bconst 2 *** bconst 3)) >>>
                    bassoclp >>> bfirst (bzipWith (*)) >>> bzipWith (*) >>> assertb "tstAssocp" (== 42)


allTests = tstConst >>> tstFmap >>> tstZip >>> tstSwap >>> tstAssocp
       >>> tstSplitL >>> tstSplitR >>> tstInL >>> tstInR
       >>> tstDisjoinL >>> tstDisjoinR
       >>> tstDeadOutput
       >>> bvoid (bconst "Hit Ctrl+C to End!" >>> bprint)
       

--joinTests :: 
-- seems like should have a monoid, here. 

-- rotate from 0..99 then back again, quickly (every 1/10th second)
-- this is intended to serve as a simple variable for tests.
rotateI :: B (S P0 ()) (S P0 Int)
rotateI = bclockOfFreq 10 >>> bfmap tkI
    where tkI = fromInteger . (`div` sTenth) . (`mod` sTen) . tmNanos
          sTen   = 10000000000   -- 10 seconds
          sTenth =   100000000   -- 100 milliseconds

cascade :: B (S P0 ()) (S P0 Int :|: S P0 Int)
cascade = rotateI >>> bsplitOn (\ x -> (x `mod` 20 < 10)) >>> (bprintWith show +++ bprintWith (\x -> "      " ++ show x))

                              

-- tests to perform:
--  delay and synch
--  
--  anticipation (bpeek)
--  multi-threaded computation - cross, return
--  dead-code elimination
--    on target (bfst/bsnd)
--    on source (binl/binr)
--  split... just test twice with Left and Right?
--  
--  Might be nice to add a few utilities to sirea-core:
--    logging to console, runtime assertions
--  

main :: IO ()
main = runSireaApp $ allTests
   

-- HOW will I make it convenient to write tests
-- for Sirea? Perhaps use some sort of `expect`
-- model? use unsafeOnUpdateB to push updates
-- to a channel for unit testing?


-- TESTS TO WRITE:
--  fmap
--  bzip
--  bsplit
--  bsynch
--  

