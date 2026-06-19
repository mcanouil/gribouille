// guide-legend(align:) and the legend-text align: justify entry labels.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let make-panel(title, ..args) = plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", colour: "class"),
  layers: (geom-point(size: 2.5pt),),
  labels: labels(
    title: title,
    x: "Displacement (L)",
    y: "Highway mpg",
    colour: "Class",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
  ..args,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  make-panel("default (vertical: left)"),
  make-panel(
    "guide-legend(align: right)",
    guides: guides(colour: guide-legend(align: right)),
  ),
  make-panel(
    "theme(legend-text: element-text(align: center))",
    theme: theme-minimal() + theme(legend-text: element-text(align: center)),
  ),
)
