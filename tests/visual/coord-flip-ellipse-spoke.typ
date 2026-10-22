// Smoke render: geom-ellipse and geom-spoke follow coord-flip.
//
// Each row puts an unflipped panel next to the same plot under coord-flip.
// The ellipse rotation and the spoke direction resolve in the user's x/y
// space, so under the flip each shape mirrors across the diagonal: the
// ellipse tilted at 30 degrees from the user's x axis now leans at 60 degrees
// from the horizontal, and every spoke turns the same way.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let e = (
  (x0: 0, y0: 0, a: 3, b: 1, angle: calc.pi / 6),
  (x0: 6, y0: 2, a: 1.5, b: 0.5, angle: 0),
)
#let s = range(0, 4).map(i => (
  x: i,
  y: 1 + calc.rem(i, 2),
  angle: i * calc.pi / 8,
))

#let pair(data, mapping, layer, ..args) = (false, true).map(flip => plot(
  data: data,
  mapping: mapping,
  layers: (layer,),
  ..args,
  coord: if flip { coord-flip() } else { coord-cartesian() },
  width: 6cm,
  height: 6cm,
))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  ..pair(
    e,
    aes(x0: "x0", y0: "y0", a: "a", b: "b", angle: "angle"),
    geom-ellipse(alpha: 0.4),
  ),
  ..pair(
    s,
    aes(x: "x", y: "y", angle: "angle"),
    geom-spoke(radius: 1),
    scales: scales(
      x: scale-continuous(limits: (0, 4)),
      y: scale-continuous(limits: (0, 4)),
    ),
  ),
)
