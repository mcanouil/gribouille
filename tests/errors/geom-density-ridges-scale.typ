// `geom-density-ridges()` rejects a negative scale.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-density-ridges: scale must be a number of at least 0

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-density-ridges(scale: -1)
