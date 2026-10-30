// `cut-number` fails when quantile breaks tie, which would give zero-width bins.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: cut-number: quantile breaks are not distinct

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#cut-number((1, 1, 1, 1, 5), n: 4)
