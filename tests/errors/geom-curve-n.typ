// `geom-curve()` rejects a sample count below 1.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-curve: n must be a positive integer

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-curve(n: 0)
