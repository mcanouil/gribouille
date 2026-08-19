// A faceted coord-radial plot keeps its tick labels on every panel: the
// labels ring the inside of each circle rather than sitting on a shared edge,
// so a panel with none would have no scale to read against. The angular
// labels follow the sweep, `y` under coord-radial(theta: "y").

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let quarters = (
  (slice: "all", value: 5, part: "Direct", quarter: "Q1"),
  (slice: "all", value: 3, part: "Partner", quarter: "Q1"),
  (slice: "all", value: 4, part: "Direct", quarter: "Q2"),
  (slice: "all", value: 4, part: "Partner", quarter: "Q2"),
  (slice: "all", value: 6, part: "Direct", quarter: "Q3"),
  (slice: "all", value: 2, part: "Partner", quarter: "Q3"),
  (slice: "all", value: 3, part: "Direct", quarter: "Q4"),
  (slice: "all", value: 5, part: "Partner", quarter: "Q4"),
)

#plot(
  data: quarters,
  mapping: aes(x: "slice", y: "value", fill: "part"),
  layers: (geom-col(width: 1, position: "stack"),),
  coord: coord-radial(theta: "y"),
  scales: scales(y: scale-continuous(expand: false)),
  facet: facet-wrap("quarter", ncolumn: 2),
  labels: labels(title: "Revenue Split by Quarter", fill: "Channel"),
  theme: theme-minimal(),
  width: 12cm,
  height: 10cm,
)
