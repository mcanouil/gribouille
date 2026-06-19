// guide-legend(position: ...): every accepted placement value.
//
// The four side strings push the legend into the matching margin; a Typst
// alignment (e.g. top + right) places it inside the panel anchored to that
// corner; a dict (x:, y:) / (dx:, dy:) offsets it anywhere on the canvas.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "b"),
  (x: 3, y: 3, g: "c"),
)

#let make-panel(title, pos) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt),),
  guides: guides(colour: guide-legend(position: pos)),
  labels: labels(title: title),
  width: 8cm,
  height: 5cm,
)

#grid(
  columns: 2,
  column-gutter: 0.6cm,
  row-gutter: 0.6cm,
  make-panel("position: \"right\" (default)", "right"),
  make-panel("position: \"top\"", "top"),

  make-panel("position: \"bottom\"", "bottom"),
  make-panel("position: \"left\"", "left"),

  make-panel("position: top + right (inside)", top + right),
  make-panel("position: (x: 70%, y: 30%)", (x: 70%, y: 30%)),
)
