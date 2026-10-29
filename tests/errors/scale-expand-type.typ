// `scales()` fails when a side of `expand` is not a ratio or a length.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-discrete: expand must be a ratio, a length, a relative length, or a (lo, hi) pair of them; got "5%"

#import "/lib.typ": scale-discrete, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-discrete(expand: "5%"))
