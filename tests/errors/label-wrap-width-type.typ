// `label-wrap` rejects a `width` that is not an integer.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: label-wrap: width must be a positive integer

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let l = label-wrap(width: "3")
