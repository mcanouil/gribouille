// A theme sets the colour bar tick length with `legend-ticks` and the gap
// between the title and the strip with `guide-spacing`. The left plot keeps the
// defaults and the right one lengthens both, so its labels and its strip sit
// further out.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let make(title, ..theme-args) = plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", colour: "body-mass"),
  layers: (geom-point(size: 1.5pt),),
  labels: labels(title: title, x: "Flipper length", y: "Body mass"),
  theme: theme(..theme-args),
  width: 8cm,
  height: 6.5cm,
)

#stack(
  dir: ltr,
  spacing: 0.5cm,
  make("default"),
  make(
    "long tick, wide gap",
    legend-ticks: element-tick(length: 0.3cm),
    guide-spacing: 0.4cm,
  ),
)
