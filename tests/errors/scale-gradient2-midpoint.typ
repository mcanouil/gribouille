// `scales()` fails when `midpoint` is not a number.
//
// A string used to raise the raw Typst error `cannot compare float and string`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-gradient2: midpoint must be a number; got "a"

#import "/lib.typ": scale-gradient2, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-gradient2(midpoint: "a"))
