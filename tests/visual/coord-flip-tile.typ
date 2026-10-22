// Smoke render: geom-tile sizes follow coord-flip.
//
// Each row puts an unflipped panel next to the same plot under coord-flip.
// `width` spans the user's x axis and `height` the user's y axis, so the wide
// flat tiles of the unflipped panel stand tall and narrow under the flip, for
// a fixed height and for a mapped one alike.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(0, 6).map(i => (
  x: calc.rem(i, 3),
  y: calc.floor(i / 3),
  h: 0.1 + calc.rem(i, 3) * 0.2,
  v: i,
))

#let pair(mapping, layer) = (false, true).map(flip => plot(
  data: d,
  mapping: mapping,
  layers: (layer,),
  coord: if flip { coord-flip() } else { coord-cartesian() },
  width: 6cm,
  height: 5cm,
))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  ..pair(aes(x: "x", y: "y", fill: "v"), geom-tile(width: 0.9, height: 0.3)),
  ..pair(aes(x: "x", y: "y", height: "h", fill: "v"), geom-tile(width: 0.9)),
)
