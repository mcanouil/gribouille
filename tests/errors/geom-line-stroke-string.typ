// A string `stroke` on a geom fails at the call, naming the geom and the
// parameter. A line used to ignore it, and a point reached CeTZ with a raw
// error.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-line: stroke

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-line(stroke: "red")
