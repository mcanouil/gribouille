// `guide-axis()` fails when `angle` is not a number.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-axis: angle must be a number of degrees

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (x: (1, 2, 3), y: (1, 2, 3), g: ("a", "b", "c")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  guides: guides(x: guide-axis(angle: 45deg)),
)
