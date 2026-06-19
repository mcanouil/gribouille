// Radar chart: closed polygon under coord-radial with one vertex per axis.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let scores = (8, 6, 7, 9, 5, 8)
#let car-a = range(scores.len()).map(i => (axis: i, score: scores.at(i)))

#plot(
  data: car-a,
  mapping: aes(x: "axis", y: "score"),
  layers: (
    geom-polygon(fill: rgb("#1f77b4"), alpha: 0.4, stroke: 0.8pt),
    geom-point(size: 2pt),
  ),
  coord: coord-radial(theta: "x"),
  scales: (
    scale-x-continuous(
      limits: (0, 6),
      labels: v => if v == 6 { none } else { str(v) },
      expand: false,
    ),
    scale-y-continuous(limits: (0, 10)),
  ),
  labels: labels(title: "Vehicle Profile"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
