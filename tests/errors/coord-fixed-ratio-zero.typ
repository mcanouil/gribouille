// `coord-fixed()` rejects a ratio that is not positive.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-fixed: ratio must be a positive number

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-fixed(ratio: 0)
