// `geom-rug()` rejects a length that is not a length.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-rug: length must be a non-negative length

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-rug(length: 2)
