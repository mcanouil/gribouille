// `geom-col()` draws bars from a continuous `y`, so a discrete `y` fails
// instead of leaving an empty panel.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-col: the value axis (y) must be continuous
// expect: coord-flip()

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
  width: 8cm,
  height: 5cm,
)
