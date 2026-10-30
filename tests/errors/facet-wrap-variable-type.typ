// `facet-wrap()` rejects a variable that is not a column name string.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: facet-wrap: variable must be
// expect: column name string

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#facet-wrap(3)
