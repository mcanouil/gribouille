// `geom-label(label: "hi")` draws the constant on every row.
//
// Left: a boxed constant label at each point, as `geom-text(label:)` draws it.
// Right: a mapped `label` column, which a constant must not disturb.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let points = (
  (x: 1, y: 1, name: "a"),
  (x: 2, y: 3, name: "b"),
  (x: 3, y: 2, name: "c"),
)

#grid(
  columns: 2,
  gutter: 0.5cm,
  plot(
    data: points,
    mapping: aes(x: "x", y: "y"),
    layers: (
      geom-point(),
      geom-label(label: "hi", position: position-nudge(y: 0.3)),
    ),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: points,
    mapping: aes(x: "x", y: "y", label: "name"),
    layers: (geom-point(), geom-label(position: position-nudge(y: 0.3))),
    width: 6cm,
    height: 4cm,
  ),
)
