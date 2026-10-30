// `guide-axis()` hint is a full sentence for an angle past a quarter turn.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: Tick labels read upside down past a quarter turn.

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (x: (1, 2, 3), y: (1, 2, 3), g: ("a", "b", "c")),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  guides: guides(x: guide-axis(angle: 120)),
)
