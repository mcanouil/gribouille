// Bundled mpg dataset: highway mpg vs engine displacement, filled by class.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", fill: "class"),
  layers: (geom-point(size: 3pt, alpha: 0.85),),
  labels: labels(
    title: "Fuel Economy by Vehicle Class",
    subtitle: "Highway mpg falls as engine displacement rises",
    x: "Engine Displacement (L)",
    y: "Highway mpg",
    fill: "Class",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
