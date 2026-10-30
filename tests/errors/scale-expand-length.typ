// `scales()` fails when `expand` is an array that is not a pair.
//
// The message used to blame one piece under the scope `expand`, while the
// array had the wrong length.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: expand must be a (lo, hi) pair; got (5%, 5%, 5%)

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-continuous(expand: (5%, 5%, 5%)))
