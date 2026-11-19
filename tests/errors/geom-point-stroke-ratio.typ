// A ratio `stroke` on a geom fails at the call, as a string does. A ratio only
// has a parent stroke to scale in a theme element.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-point: stroke

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-point(stroke: 50%)
