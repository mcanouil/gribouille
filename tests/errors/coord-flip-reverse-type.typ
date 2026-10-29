// `coord-flip()` rejects a `reverse` that is neither `auto` nor a boolean.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-flip: reverse must be
// expect: boolean

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-flip(reverse: "yes")
