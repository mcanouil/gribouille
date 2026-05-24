// element-text align: title/subtitle default left, caption right, axis titles
// centred; each is independent of the container and overridable per surface.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let df = range(0, 12).map(i => (x: i, y: i * i * 0.1))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1.2pt, colour: rgb("#1f77b4")),
    geom-point(size: 3pt, fill: rgb("#1f77b4")),
  ),
  theme: theme(
    plot-title: element-text(weight: "bold", align: center),
    axis-title-x: element-text(align: right),
  ),
  labs: labs(
    title: "Centred Title",
    subtitle: "Subtitle stays left",
    caption: "Caption sits right by default",
    x: "Step (title pushed right)",
    y: "y = 0.1 × x²",
  ),
  width: 12cm,
  height: 9cm,
)
