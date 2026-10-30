// `guide-axis()` fails when `n-dodge` is below 1, where it used to clamp to 1.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-axis: n-dodge must be a whole number of at least 1

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (x: (1, 2, 3), y: (1, 2, 3), g: ("a", "b", "c")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  guides: guides(x: guide-axis(n-dodge: 0)),
)
