// Facet wrap with free y: each panel trains its own y axis on its own subset.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let series = ()
#for x in range(0, 12) {
  series.push((scale: "millis", x: x, y: 0.1 * x + 0.05))
  series.push((scale: "seconds", x: x, y: 2.0 * x + 1.0))
  series.push((scale: "minutes", x: x, y: 50.0 * x + 5.0))
}

#plot(
  data: series,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1.2pt, colour: rgb("#1f77b4")),
    geom-point(size: 2pt),
  ),
  facet: facet-wrap("scale", ncolumn: 3, scales: "free_y"),
  labels: labels(
    title: "Per-panel y axis with scales = free_y",
    subtitle: "Each panel trains its own y range so disparate magnitudes read clearly",
    x: "Step",
    y: "Value",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
