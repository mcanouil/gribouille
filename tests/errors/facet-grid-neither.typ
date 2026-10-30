// facet-grid() rejects a call with neither rows nor columns.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: facet-grid: needs rows or columns; got neither

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#facet-grid()
