// geom-freqpoly: line through binned counts, the line counterpart to a histogram.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "hwy", colour: as-factor("cyl")),
  layers: (geom-freqpoly(bins: 10, stroke: 1.2pt),),
  labels: labels(
    title: "Highway Fuel Economy by Cylinder Count",
    subtitle: "Frequency polygons make the per-group shapes easy to compare",
    x: "Highway mpg",
    y: "Vehicles",
    colour: "Cylinders",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
