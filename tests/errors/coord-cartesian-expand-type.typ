// `coord-cartesian()` rejects an `expand` that is not a boolean.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-cartesian: expand must be a boolean

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-cartesian(expand: "no")
