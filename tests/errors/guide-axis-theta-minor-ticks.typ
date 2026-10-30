// `guide-axis-theta()` fails when `minor-ticks` is not a bool.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-axis-theta: minor-ticks must be

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (x: (1, 2, 3), y: (1, 2, 3), g: ("a", "b", "c")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  coord: coord-radial(),
  guides: guides(theta: guide-axis-theta(minor-ticks: "x")),
)
