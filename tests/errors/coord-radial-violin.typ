// `coord-radial()` rejects `geom-violin`, which has no polar form.
//
// The layer used to draw nothing under the radial coord. `tools/check-errors.sh`
// compiles this file, requires the compile to fail, and requires the `error:`
// line to carry every phrase below.
//
// expect: coord-radial: does not support geom-violin
// expect: Draw this layer without coord-radial, or use geom-boxplot

#import "/lib.typ": aes, coord-radial, geom-violin, plot

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (
    (x: "a", y: 1),
    (x: "a", y: 2),
    (x: "a", y: 4),
    (x: "b", y: 2),
    (x: "b", y: 3),
    (x: "b", y: 5),
  ),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-violin(),),
  coord: coord-radial(),
  width: 6cm,
  height: 4cm,
)
