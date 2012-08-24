
{-# LANGUAGE MultiParamTypeClasses #-}

-- | `B w x y` is the raw, primitive behavior type in Sirea. 
--
-- `B` assumes that necessary hooks (into environment and resources)
-- are already formed. However, it is inconvenient to achieve those
-- hooks by hand. To model environment and convenient type-driven
-- relationships (and multi-threading with bcross), use BCX.
--
-- See Also:
--   Sirea.Link for `unsafeLnkB` - new behavior primitives.
--   Sirea.BCX for behavior with resource context
module Sirea.B 
    ( B
    ) where

import Sirea.Time
import Sirea.Behavior
-- import Sirea.Partition
import Sirea.Internal.BTypes
import Sirea.Internal.BImpl
import Sirea.Internal.BDynamic
import Data.Typeable

instance Typeable2 (B w) where
    typeOf2 _ = mkTyConApp tcB []
        where tcB = mkTyCon3 "sirea-core" "Sirea.Behavior" "B"

---------------------------
-- Concrete Instances: B --
---------------------------
-- TUNING
--   dtScanAheadB: default lookahead for constB, adjeqfB.
--   dtTouchB: compute ahead of stability for btouch.
-- Eventually I'd like to make these values adaptive, i.e. depending
-- on actual lookahead stability at runtime.
dtScanAheadB, dtTouchB :: DT
dtScanAheadB = 4.0 -- seconds ahead of stability
dtTouchB = 0.2 -- seconds ahead of stability

eqfB :: (x -> x -> Bool) -> B w (S p x) (S p x)
eqfB = unsafeEqShiftB dtScanAheadB

instance BFmap (B w) where 
    bfmap    = fmapB
    bconst c = constB c >>> eqfB ((const . const) True)
    bstrat   = stratB 
    btouch   = touchB dtTouchB
    badjeqf  = adjeqfB >>> eqfB (==)
instance BProd (B w) where
    bfirst   = firstB
    bdup     = dupB
    b1i      = s1iB
    b1e      = s1eB
    btrivial = trivialB
    bswap    = swapB
    bassoclp = assoclpB
instance BSum (B w) where
    bleft    = leftB
    bmirror  = mirrorB
    bmerge   = mergeB
    b0i      = s0iB
    b0e      = s0eB
    bvacuous = vacuousB
    bassocls = assoclsB
instance BZip (B w) where
    bzap     = zapB
instance BSplit (B w) where
    bsplit   = splitB
instance BDisjoin (B w) where 
    bdisjoin = disjoinB
instance BTemporal (B w) where
    bdelay   = delayB
    bsynch   = synchB
instance BPeek (B w) where
    bpeek    = peekB
instance Behavior (B w)

instance BDynamic (B w) (B w) where
    bevalb' dt = evalB dt >>> bright bfst

-- note: B does not support `bcross`, since B cannot 
-- track which partitions are in use. Need BCX for
-- bcross.
{-
instance BScope (B w) where
    bpushScope = unsafeChangeScopeB
    bpopScope  = unsafeChangeScopeB
-}






