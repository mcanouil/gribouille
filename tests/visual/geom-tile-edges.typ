// Smoke render: geom-tile edges train the position scales.
//
// A 3 by 2 grid of tiles with `width: 0.9` and `height: 0.3`, unflipped and
// under coord-flip. The scales widen to the outer tile edges, so the corner
// tiles sit wholly inside the panel and none is clipped at the border.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(0, 6).map(i => (
  x: calc.rem(i, 3),
  y: calc.floor(i / 3),
  v: i,
))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..(false, true).map(flip => plot(
    data: d,
    mapping: aes(x: "x", y: "y", fill: "v"),
    layers: (geom-tile(width: 0.9, height: 0.3),),
    coord: if flip { coord-flip() } else { coord-cartesian() },
    width: 6cm,
    height: 5cm,
  )),
)
