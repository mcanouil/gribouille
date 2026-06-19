// geom-count: scatter where each unique (x, y) is drawn once and the count
// is exposed as the size aesthetic via stat-sum.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "cyl", y: "class"),
  layers: (geom-count(fill: rgb("#1f77b4"), alpha: 0.7),),
  scales: (scale-x-continuous(breaks: (4, 6, 8)),),
  labels: labels(
    title: "Vehicle Frequency by Cylinder Count and Class",
    subtitle: "Marker area scales with the number of rows in each cell",
    x: "Cylinders",
    y: "Class",
    size: "Vehicles",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
