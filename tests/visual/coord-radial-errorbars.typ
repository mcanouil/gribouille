// Smoke render: errorbar and errorbarh follow the polar grid under
// coord-radial.
//
// When the bar sweeps theta, its spine is an arc at constant radius and each
// cap points at the centre. When the bar runs along the radius, its spine
// stays a straight spoke and each cap is an arc across the slot. A Typst
// length cap near the centre stops at the centre and does not cross it.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let bars = range(1, 5).map(i => (
  x: i,
  y: i,
  lo: i * 0.5,
  hi: i * 2.5,
))

#let near-centre = (
  (x: 1, lo: 1, hi: 3),
  (x: 1.04, lo: 4, hi: 6),
  (x: 4, lo: 2, hi: 5),
)

#let cell(mapping, layers, theta, data: bars) = plot(
  data: data,
  mapping: mapping,
  layers: layers,
  coord: coord-radial(theta: theta),
  width: 4cm,
  height: 4cm,
)

#let vertical = aes(x: "x", ymin: "lo", ymax: "hi")
#let horizontal = aes(y: "y", xmin: "lo", xmax: "hi")

#grid(
  columns: 4,
  column-gutter: 0.4cm,
  row-gutter: 0.4cm,
  cell(vertical, (geom-errorbar(),), "y"),
  cell(horizontal, (geom-errorbarh(),), "x"),
  cell(vertical, (geom-errorbar(),), "x"),
  cell(horizontal, (geom-errorbarh(),), "y"),
  cell(vertical, (geom-errorbar(width: 0.3cm),), "y", data: near-centre),
)
