// Continuous axis transformations: log10, sqrt, and reverse on the y axis.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")
#let d = range(1, 11).map(i => (x: i, y: calc.pow(2, i)))

#let panel(title, scales) = plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent),
    geom-point(size: 2pt, fill: accent),
  ),
  scales: scales,
  labels: labels(title: title, x: "X", y: "2^x"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  panel("Linear y", ()),
  panel("Log10 y", (scale-y-log10(),)),
  panel("Sqrt y", (scale-y-sqrt(),)),
  panel("Reversed y", (scale-y-reverse(),)),
)
