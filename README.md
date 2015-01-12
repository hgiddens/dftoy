# Pedagogic toys for Dwarf Fortress

Not really intended to be useful but rather to play round with ideas and
present simple examples of Haskell.

I have no intension of making this work on anything other that OS X.

## Building

Install the [Haskell platform](https://www.haskell.org/platform/). You can do
this using Homebrew but I'd recommend just using their installer
directly. Then check this out and, in its directory, run:

    $ cabal sandbox init

This is to stop cabal spewing crap everywhere. Then to actually build
everything:
      
    $ cabal build

## Programs

### Mapper

This is a simple program to test the other programs that inspect the memory of
external processes. It (currently) just allocates two (separated) pages of
memory (a 4k page size is assumed; see `pagesize(1)`), prints their address to
standard output, then waits for a keypress before exiting.
