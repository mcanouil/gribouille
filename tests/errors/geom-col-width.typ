// `geom-col()` rejects a width outside (0, 1].
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-col: width must be in (0, 1]

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-col(width: 3)
