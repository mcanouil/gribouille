// A bad `labels` value names the public `cut-*` function, not `cut`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: cut-interval: labels must be `auto` or an array

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#cut-interval((1, 2, 3), n: 2, labels: "ab")
