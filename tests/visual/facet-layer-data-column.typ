// Smoke render: a facet column that only the layer data carries.
//
// The plot has no data of its own, so the facet variable is checked against the
// layer data and the plot splits into one panel per level of `g`.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 3, g: "a"),
  (x: 1, y: 2, g: "b"),
  (x: 2, y: 1, g: "b"),
)

#plot(
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(data: d),),
  facet: facet-wrap("g"),
  width: 10cm,
  height: 5cm,
)
