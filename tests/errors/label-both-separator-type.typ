// `label-both` rejects a `separator` that is not a string.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: label-both: separator must be a string

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let l = label-both(separator: 1)
