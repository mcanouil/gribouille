// A theme geom slot that is not an element-geom fails instead of being ignored.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: theme: geom must be an `element-geom(...)` record

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let d = ((x: 1, y: 2),)
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  theme: theme(geom: element-line()),
)
