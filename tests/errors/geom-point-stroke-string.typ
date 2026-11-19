// A string `stroke` on a point fails at the call, naming the geom and the
// parameter, where it used to reach CeTZ with a raw error.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-point: stroke

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-point(stroke: "red")
