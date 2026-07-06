// coord-transform: warp the displayed coordinates without setting transform
// on each scale. Equivalent to scale-continuous(transform: ...) in the
// current implementation; provided as a coord-level entry point.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1),
  (x: 3, y: 5),
  (x: 10, y: 25),
  (x: 30, y: 100),
  (x: 100, y: 500),
  (x: 300, y: 2500),
  (x: 1000, y: 10000),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-line(stroke: 0.6pt, alpha: 0.4), geom-point(size: 3pt)),
  coord: coord-transform(x: "log10", y: "log10"),
  guides: guides(x: guide-axis-logticks(), y: guide-axis-logticks()),
  labels: labels(title: "coord-transform(x: \"log10\", y: \"log10\")"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

// Mixing with scale-level transform: coord-transform overrides the scale's
// transform so the final visual reflects the coord setting.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  scales: scales(y: scale-continuous(transform: "sqrt")),
  coord: coord-transform(x: "log10"),
  labels: labels(title: "Scale-Y Sqrt + Coord-Transform X log10"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
