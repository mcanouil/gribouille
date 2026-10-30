// `cut-width` rejects a `width` that is not a number.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: cut-width: width must be a positive number

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#cut-width((1, 2, 3), width: "1")
