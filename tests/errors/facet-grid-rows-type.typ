// `facet-grid()` rejects a row variable that is not a column name string.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: facet-grid: rows must be
// expect: column name string

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#facet-grid(rows: 3)
