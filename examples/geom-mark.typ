// geom-mark: enclose each cluster with a chosen shape.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let panel(title, method, expand) = plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", fill: "species"),
  layers: (
    geom-mark(method: method, expand: expand, alpha: 0.25),
    geom-point(size: 2pt, alpha: 0.85),
  ),
  scales: (
    scale-y-continuous(labels: format-comma()),
  ),
  guides: guides(
    x: guide-axis(n-dodge: 2),
  ),
  labels: labels(
    title: title,
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
    fill: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  panel(`method: "hull"`, "hull", 8pt),
  panel(`method: "ellipse"`, "ellipse", 10pt),
  panel(`method: "rect"`, "rect", 8pt),
  panel(`method: "circle"`, "circle", 8pt),
)
