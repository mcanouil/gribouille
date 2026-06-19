// legend-background element-rect renders on every legend placement.
//
// Each panel sets a coloured fill + a contrasting stroke on
// `legend-background`. The themed rect should wrap the whole stacked legend
// (one bbox per side) and the colour swatch in the inside-corner panel.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "b"),
  (x: 3, y: 3, g: "c"),
)

#let themed = theme(
  legend-background: element-rect(
    fill: rgb("#e6f4ea"),
    colour: rgb("#2e7d4a"),
    stroke: 0.4pt,
  ),
)

#let panel(label, pos) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt),),
  guides: guides(colour: guide-legend(position: pos)),
  labels: labels(title: label),
  theme: themed,
  width: 8cm,
  height: 4cm,
)

#grid(
  columns: 2,
  column-gutter: 0.6cm,
  row-gutter: 0.6cm,
  panel("right", "right"), panel("top", "top"),
  panel("bottom", "bottom"), panel("left", "left"),
  panel("inside top + right", top + right),
)
