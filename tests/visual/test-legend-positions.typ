// Smoke render: every legend `position` value lays out without overlap.
//
// Slice 6 wires the multi-side draw pass. Each panel below carries one
// of the supported placements: the four sides, an inside-corner alignment,
// and an explicit (x:, y:) offset. The colour legend follows the requested
// position; the size mapping demonstrates a second guide on the right.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "b"),
  (x: 3, y: 3, g: "c"),
)

#let panel(label, pos) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt),),
  guides: guides(colour: guide-legend(position: pos)),
  labels: labels(title: label),
  width: 8cm,
  height: 4cm,
)

#grid(
  columns: 2,
  column-gutter: 0.6cm,
  row-gutter: 0.6cm,
  panel("right (default)", "right"), panel("top", "top"),
  panel("bottom", "bottom"), panel("left", "left"),
  panel("inside top + right", top + right),
  panel("inside (x: 70%, y: 30%)", (x: 70%, y: 30%)),
)
