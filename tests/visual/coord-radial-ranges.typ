// Smoke render: linerange and pointrange follow the polar grid under
// coord-radial.
//
// With `theta: "y"` the range sweeps theta, so each range is an arc at constant
// x, not a straight chord. With `theta: "x"` the range runs along the radius
// and stays a straight spoke.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let ranges = range(1, 5).map(i => (
  x: i,
  y: i * 2,
  lo: i * 0.5,
  hi: i * 2.5,
))

#let cell(data, mapping, layers, theta, ..rest) = plot(
  data: data,
  mapping: mapping,
  layers: layers,
  coord: coord-radial(theta: theta),
  width: 4cm,
  height: 4cm,
  ..rest,
)

#let band = aes(x: "x", ymin: "lo", ymax: "hi")
#let mid = aes(x: "x", y: "y", ymin: "lo", ymax: "hi")

#grid(
  columns: 4,
  column-gutter: 0.4cm,
  row-gutter: 0.4cm,
  cell(ranges, band, (geom-linerange(),), "y"),
  cell(ranges, mid, (geom-pointrange(size: 1.5pt),), "y"),
  cell(ranges, band, (geom-linerange(),), "x"),
  cell(ranges, mid, (geom-pointrange(size: 1.5pt),), "x"),
)
