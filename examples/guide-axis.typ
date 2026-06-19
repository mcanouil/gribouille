// guide-axis customises tick label rotation and dodging on a discrete axis.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let make-panel(title, gs) = plot(
  data: mpg,
  mapping: aes(x: "manufacturer"),
  layers: (geom-bar(),),
  guides: gs,
  scales: (scale-y-continuous(name: "Vehicles in sample"),),
  labels: labels(title: title, x: "Manufacturer"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  make-panel("Default tick labels overlap", (:)),
  make-panel("guides(x: guide-axis(angle: 30))", guides(
    x: guide-axis(angle: 30),
  )),
  make-panel("guides(x: guide-axis(n-dodge: 2))", guides(
    x: guide-axis(n-dodge: 2),
  )),
)
