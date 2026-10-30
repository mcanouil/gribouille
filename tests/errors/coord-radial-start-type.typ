// `coord-radial()` rejects a `start` that is not a number.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-radial: start must be a number

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-radial(start: "a")
