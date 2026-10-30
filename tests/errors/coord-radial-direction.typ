// `coord-radial()` rejects a `direction` other than 1 or -1.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-radial: direction must be one of
// expect: got 2

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-radial(direction: 2)
