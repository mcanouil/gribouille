// `scales()` fails when a size `range` is not a pair of lengths.
//
// A bare length used to raise the raw Typst error `cannot destructure length`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: range must be a (lo, hi) pair of lengths; got 3pt

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(size: scale-continuous(range: 3pt))
