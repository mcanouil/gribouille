// Smoke render: geom-qq and geom-qq-line read a mapped sample.
//
// The left panel maps the column to `sample`, as the geom documentation says.
// The right panel maps the same column to `y`. The two panels must look the same.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (2.1, 3.4, 1.8, 5.2, 4.4, 3.9, 2.7, 6.1, 3.0, 4.8).map(v => (v: v))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..(aes(sample: "v"), aes(y: "v")).map(m => plot(
    data: d,
    mapping: m,
    layers: (geom-qq(), geom-qq-line()),
    width: 6cm,
    height: 5cm,
  )),
)
