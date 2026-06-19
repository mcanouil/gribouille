// geom-curve: quadratic bezier connectors with mapped colour.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let connections = (
  (x: 0, y: 0, xend: 1, yend: 1.5, flow: "primary"),
  (x: 0, y: 0, xend: 1, yend: -1, flow: "primary"),
  (x: 1, y: 1.5, xend: 2, yend: 0.5, flow: "feedback"),
  (x: 1, y: -1, xend: 2, yend: 0.5, flow: "feedback"),
)

#let panel(title, curvature) = plot(
  data: connections,
  mapping: aes(x: "x", y: "y", xend: "xend", yend: "yend", colour: "flow"),
  layers: (
    geom-curve(curvature: curvature, stroke: 1.2pt),
    geom-point(size: 3pt),
  ),
  scales: (
    scale-x-continuous(breaks: (0, 1, 2)),
    scale-y-continuous(breaks: (-1, 0, 1, 1.5)),
  ),
  labels: labels(title: title, x: "Stage", y: "Lane", colour: "Flow"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  panel("curvature = 0.5", 0.5),
  panel("curvature = -0.5", -0.5),
)
