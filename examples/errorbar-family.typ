// Errorbar family: four range-style geoms over the same per-quarter summary.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#let revenue = (
  (quarter: 1, mean: 12.4, lo: 11.0, hi: 13.5),
  (quarter: 2, mean: 14.1, lo: 13.0, hi: 15.4),
  (quarter: 3, mean: 13.6, lo: 12.0, hi: 14.8),
  (quarter: 4, mean: 16.2, lo: 14.6, hi: 17.7),
)

#let panel(title, layers) = plot(
  data: revenue,
  mapping: aes(x: "quarter", y: "mean", ymin: "lo", ymax: "hi"),
  layers: layers,
  scales: scales(x: scale-continuous(breaks: (1, 2, 3, 4)), y: scale-continuous(labels: format-currency(symbol: "$", digits: 1))),
  labels: labels(title: title, x: "Quarter", y: "Revenue"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  panel("geom-errorbar", (
    geom-errorbar(width: 0.4, stroke: 1pt, colour: accent),
    geom-point(size: 3pt, fill: accent),
  )),
  panel("geom-linerange", (
    geom-linerange(stroke: 1.2pt, colour: accent),
    geom-point(size: 3pt, fill: accent),
  )),
  panel("geom-crossbar", (
    geom-crossbar(fill: rgb("#a8c6d8"), stroke: 1pt, colour: accent),
  )),
  panel("geom-pointrange", (
    geom-pointrange(size: 3pt, stroke: 1.2pt, colour: accent),
  )),
)
