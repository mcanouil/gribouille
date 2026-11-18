// Under `coord-radial()`, a discrete `y` in `geom-col()` fails with a hint
// for the radial layout, not the `coord-flip()` one.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-col: the value axis (y) must be continuous
// expect: coord-radial(theta:

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0pt)

#let d = (
  (k: "a", v: 3),
  (k: "b", v: 5),
)

#plot(
  data: d,
  mapping: aes(x: "v", y: "k"),
  layers: (geom-col(),),
  coord: coord-radial(),
  width: 8cm,
  height: 8cm,
)
