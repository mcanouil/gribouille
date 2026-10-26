// Smoke render: path-like geoms follow the polar grid under coord-radial.
//
// Each panel draws edges over a wide sweep of theta, so every edge would be a
// visible straight chord if the coord did not curve it. The panels draw
// line, path, step, area, ribbon, polygon, segment, spoke, and abline under
// coord-radial. Polygons keep straight edges under coord-radial, so a radar
// polygon stays a star; every other panel curves. The last panel draws abline
// over points on a log10 radial scale, where the line bends with the warped
// radius as well as the sweep.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let pts = (
  (x: 0, y: 2),
  (x: 3, y: 5),
  (x: 5, y: 3),
  (x: 8, y: 4),
)
#let band = pts.map(p => p + (lo: p.y - 1.5, hi: p.y + 1))
#let shape = (5, 3, 6, 1, 5, 4).enumerate().map(((i, y)) => (x: i, y: y))
#let ends = (
  (x: 0, y: 3, xe: 3, ye: 3),
  (x: 4, y: 1, xe: 7, ye: 4),
)
#let rays = (
  (x: 0, y: 3, angle: 0, r: 4),
  (x: 2, y: 1, angle: calc.pi / 2, r: 2),
  (x: 8, y: 4, angle: calc.pi, r: 3),
)
#let growth = range(0, 5).map(i => (x: i * 2, y: calc.pow(3, i)))

#let cell(data, mapping, layers, ..rest) = plot(
  data: data,
  mapping: mapping,
  layers: layers,
  coord: coord-radial(),
  width: 4cm,
  height: 4cm,
  ..rest,
)

#grid(
  columns: 5,
  column-gutter: 0.4cm,
  row-gutter: 0.4cm,
  cell(pts, aes(x: "x", y: "y"), (geom-line(),)),
  cell(pts, aes(x: "x", y: "y"), (geom-path(),)),
  cell(pts, aes(x: "x", y: "y"), (geom-step(),)),
  cell(pts, aes(x: "x", y: "y"), (geom-area(),)),
  cell(band, aes(x: "x", ymin: "lo", ymax: "hi"), (geom-ribbon(),)),
  cell(shape, aes(x: "x", y: "y"), (geom-polygon(),)),
  cell(ends, aes(x: "x", y: "y", xend: "xe", yend: "ye"), (geom-segment(),)),
  cell(rays, aes(x: "x", y: "y", angle: "angle", radius: "r"), (
    geom-spoke(),
  )),
  cell(pts, aes(x: "x", y: "y"), (
    geom-point(size: 1.5pt),
    geom-abline(slope: 0.3, intercept: 2),
  )),
  cell(
    growth,
    aes(x: "x", y: "y"),
    (geom-point(size: 1.5pt), geom-abline(slope: 10, intercept: 1)),
    scales: scales(y: scale-log10()),
  ),
)
