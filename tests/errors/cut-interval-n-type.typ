// `cut-interval` rejects an `n` that is not an integer.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: cut-interval: n must be a positive integer

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#cut-interval((1, 2, 3), n: "4")
