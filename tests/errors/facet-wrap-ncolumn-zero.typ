// `facet-wrap()` rejects an `ncolumn` below 1.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: facet-wrap: ncolumn must be
// expect: positive integer

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#facet-wrap("g", ncolumn: 0)
