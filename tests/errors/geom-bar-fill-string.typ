// A wrapper geom reports a string `fill` under its own name, not the name of
// the geom it delegates to.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-bar: fill

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-bar(fill: "red")
