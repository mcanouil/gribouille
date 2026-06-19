// geom-errorbarh: horizontal error bars per category, plus point estimates.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let summary = (
  (class: "compact", mean: 28.7, lo: 26.4, hi: 31.0),
  (class: "midsize", mean: 27.2, lo: 24.6, hi: 29.8),
  (class: "subcompact", mean: 28.1, lo: 25.0, hi: 31.2),
  (class: "suv", mean: 18.1, lo: 15.4, hi: 20.8),
  (class: "pickup", mean: 16.9, lo: 14.5, hi: 19.3),
  (class: "minivan", mean: 22.2, lo: 19.7, hi: 24.7),
  (class: "2seater", mean: 24.8, lo: 22.0, hi: 27.6),
)

#plot(
  data: summary,
  mapping: aes(y: "class", x: "mean", xmin: "lo", xmax: "hi"),
  layers: (
    geom-errorbarh(height: 0.35, stroke: 1.2pt, colour: rgb("#1f77b4")),
    geom-point(size: 3.5pt, fill: rgb("#1f77b4")),
  ),
  labels: labels(
    title: "Highway Fuel Economy by Vehicle Class",
    subtitle: "Horizontal error bars span the 95% confidence interval around each mean",
    x: "Highway mpg",
    y: "Class",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
