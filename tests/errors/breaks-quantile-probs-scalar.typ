// `breaks-quantile` names `probs` when it is not an array.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: breaks-quantile: probs must be an array of numbers

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let b = breaks-quantile(probs: 0.5)
