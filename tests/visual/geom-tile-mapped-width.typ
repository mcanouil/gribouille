// Smoke render: geom-tile reads a mapped width.
//
// Each tile takes its width from the `w` column, so the middle tile is wider than
// the two narrow outer tiles. The second panel is the same plot under
// coord-flip, where the width still spans the user's x axis, so the middle tile
// is taller instead.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(0, 3).map(i => (
  x: i,
  y: 0,
  w: if i == 1 { 0.8 } else { 0.15 },
  v: i,
))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..(false, true).map(flip => plot(
    data: d,
    mapping: aes(x: "x", y: "y", width: "w", fill: "v"),
    layers: (geom-tile(height: 0.5),),
    coord: if flip { coord-flip() } else { coord-cartesian() },
    width: 6cm,
    height: 5cm,
  )),
)
