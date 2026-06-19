// theme() overrides: tune text sizes, panel background, and grid colour.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let df = range(0, 12).map(i => (x: i, y: i * i * 0.1))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1.2pt, colour: rgb("#d6604d")),
    geom-point(size: 3pt, fill: rgb("#d6604d")),
  ),
  theme: theme(
    axis-title: element-text(size: 12pt),
    axis-text: element-text(size: 10pt),
    panel-background: element-rect(fill: rgb("#f7f0e7")),
    panel-grid: element-line(colour: rgb("#d9cfbf")),
  ),
  labels: labels(
    title: "theme() Overrides",
    subtitle: "Larger axis titles, a cream panel fill, and a soft grid",
    x: "Step",
    y: "y = 0.1 × x²",
  ),
  width: 12cm,
  height: 9cm,
)
