// Smoke render: `facet-grid` with rows and columns, where the column variable
// is `none` in every row of the data.
//
// No panel can be laid out, so the plot renders blank as `facet-wrap` does,
// and nothing raises `array index out of bounds`.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, a: "p", b: none),
  (x: 2, y: 2, a: "q", b: none),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  facet: facet-grid(rows: "a", columns: "b"),
  width: 8cm,
  height: 6cm,
)
