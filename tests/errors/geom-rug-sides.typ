// `geom-rug()` rejects a side code other than b, t, l, r.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-rug: sides must be a string of the codes

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-rug(sides: "zq")
