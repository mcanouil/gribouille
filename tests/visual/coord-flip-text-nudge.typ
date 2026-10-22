// Smoke render: text, label, and typst nudges follow coord-flip.
//
// Each row puts an unflipped panel next to the same plot under coord-flip.
// `nudge-x` moves a label along the user's x axis and `nudge-y` along the
// user's y axis, for a number in data units and for a length alike. Under the
// flip the user's x runs vertically, so a label that the unflipped panel
// moves right moves up instead, and one that it moves up moves right.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, name: "a"),
  (x: 2, y: 3, name: "b"),
  (x: 3, y: 2, name: "c"),
)

#let pair(layer) = (false, true).map(flip => plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "name"),
  layers: (geom-point(), layer),
  scales: scales(
    x: scale-continuous(limits: (0, 4)),
    y: scale-continuous(limits: (0, 4)),
  ),
  coord: if flip { coord-flip() } else { coord-cartesian() },
  width: 5cm,
  height: 5cm,
))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  ..pair(geom-text(nudge-x: 0.4)),
  ..pair(geom-label(nudge-x: 0.6cm)),
  ..pair(geom-typst(nudge-y: 0.4cm)),
)
