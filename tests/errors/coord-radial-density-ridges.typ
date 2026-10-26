// `coord-radial()` rejects `geom-density-ridges`, which has no polar form.
//
// The layer used to draw nothing under the radial coord. `tools/check-errors.sh`
// compiles this file, requires the compile to fail, and requires the `error:`
// line to carry every phrase below.
//
// expect: coord-radial: does not support geom-density-ridges
// expect: Draw this layer without coord-radial, or use geom-boxplot

#import "/lib.typ": aes, coord-radial, geom-density-ridges, plot

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (
    (x: 1, grp: "a"),
    (x: 2, grp: "a"),
    (x: 4, grp: "a"),
    (x: 2, grp: "b"),
    (x: 3, grp: "b"),
    (x: 5, grp: "b"),
  ),
  mapping: aes(x: "x", y: "grp"),
  layers: (geom-density-ridges(),),
  coord: coord-radial(),
  width: 6cm,
  height: 4cm,
)
