// `scales()` fails when continuous `limits` are not a pair.
//
// A bare number used to raise the raw Typst error `cannot destructure integer`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: limits must be a (lo, hi) pair; got 5

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-continuous(limits: 5))
