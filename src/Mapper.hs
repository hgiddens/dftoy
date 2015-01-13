{-# LANGUAGE CApiFFI #-}

import Control.Monad (void)
import Data.Bits (xor)
import Foreign.C
import Foreign.Ptr
import System.IO (BufferMode(NoBuffering), hSetBuffering, stdin)
import System.Posix.Process (getProcessID)
import System.Posix.Types
import Text.Printf (printf)

-- Bunch of FFI declarations for mmap(2) and friends. I did find a Haskell mmap
-- library on Hackage but it only dealt with mapping actual files.
foreign import capi "sys/mman.h value MAP_ANON" map_anon :: CInt
foreign import capi "sys/mman.h value MAP_PRIVATE" map_private :: CInt
foreign import capi "sys/mman.h value PROT_READ" prot_read :: CInt
foreign import capi "sys/mman.h value PROT_WRITE" prot_write :: CInt
foreign import capi "sys/mman.h mmap" mmap :: Ptr () -> CSize -> CInt -> CInt -> CInt -> COff -> IO (Ptr ())
foreign import capi "sys/mman.h munmap" munmap :: Ptr () -> CSize -> IO CInt

foreign import capi "mach/vm_statistics.h VM_MAKE_TAG" vm_make_tag :: CInt -> CInt
foreign import capi "mach/vm_statistics.h value VM_MEMORY_APPLICATION_SPECIFIC_1" app_memory_1 :: CInt

blockSize :: CSize
blockSize = CSize 4096

-- Map a page of memory. It's tagged appropriately to make it easier to find
-- via vmmap(1).
--
-- Currently there's no error checking :(
allocateBlock :: IO (Ptr ())
allocateBlock = mmap addr len prot flags fd offset
    where
      addr = nullPtr -- don't care
      len = blockSize
      prot = prot_read `xor` prot_write
      flags = map_anon `xor` map_private
      fd = vm_make_tag app_memory_1
      offset = COff 0 -- ignored

freeBlock :: Ptr () -> IO ()
freeBlock ptr = do
  result <- munmap ptr blockSize
  if (result == CInt 0)
  then return ()
  else fail "munmap failed :("

waitForKey :: IO ()
waitForKey = do
  hSetBuffering stdin NoBuffering
  void getChar
  putStrLn ""

main :: IO ()
main = do
  pid <- getProcessID
  putStrLn $ printf "Started up with PID %s" (show pid)
  addr <- allocateBlock
  putStrLn $ printf "Allocated block at %0#16x" (toInteger (ptrToIntPtr addr))
  -- we allocate a temp block here which we later free to try and prevent the
  -- blocks addr and addr' abutting (which means they show up as a single, two
  -- page block in vmmap.
  tmp <- allocateBlock
  addr' <- allocateBlock
  freeBlock tmp
  putStrLn $ printf "Allocated block at %0#16x" (toInteger (ptrToIntPtr addr'))
  putStrLn "Press a key to continue"
  waitForKey
  
