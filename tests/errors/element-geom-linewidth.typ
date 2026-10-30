// An element-geom linewidth must be a length.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: element-geom: linewidth must be a length

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#element-geom(linewidth: 2)
