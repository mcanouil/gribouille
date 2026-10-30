// A geom rejects an alpha that is not a number.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-point: alpha must be a number in [0, 1]

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-point(alpha: "x")
