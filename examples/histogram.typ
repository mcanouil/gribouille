// Histogram: continuous x binned via stat-bin.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "hwy"),
  layers: (geom-histogram(bins: 12, fill: rgb("#1f77b4"), alpha: 0.85),),
  labels: labels(
    title: "Distribution of Highway Fuel Economy",
    subtitle: "12 equal-width bins via stat-bin",
    x: "Highway mpg",
    y: "Vehicles",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
