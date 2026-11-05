// A `none` cell in a column that `plot` groups by forms its own group.
//
// Left: `colour` maps a column with `none` cells. The `none` rows join in one
// line, in the fallback ink, apart from the `a` and `b` lines.
// Middle: `group` maps the same column, so each of the three groups draws its
// own line in one ink.
// Right: `geom-smooth(method: "lm")` fits one line to each `colour` group,
// with the `none` group in the fallback ink.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let rows = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "a"),
  (x: 3, y: 1.5, g: "a"),
  (x: 1, y: 2, g: none),
  (x: 2, y: 3, g: none),
  (x: 3, y: 2.5, g: none),
  (x: 1, y: 3, g: "b"),
  (x: 2, y: 4, g: "b"),
  (x: 3, y: 3.5, g: "b"),
)

#grid(
  columns: 3,
  gutter: 0.5cm,
  plot(
    data: rows,
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-line(), geom-point()),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: rows,
    mapping: aes(x: "x", y: "y", group: "g"),
    layers: (geom-line(), geom-point()),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: rows,
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(), geom-smooth(method: "lm", se: false)),
    width: 6cm,
    height: 4cm,
  ),
)
