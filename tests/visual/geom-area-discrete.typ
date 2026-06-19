// Smoke render: a filled area over a discrete x axis.
//
// Before the discrete-scale fix the area ran each x cell through
// `parse-number`, which returned `none` for a category, so every row was
// dropped and the panel rendered blank. The area must now climb the four
// quarters in domain order, not alphabetical order.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (quarter: "Q1", value: 3),
  (quarter: "Q2", value: 6),
  (quarter: "Q3", value: 4),
  (quarter: "Q4", value: 7),
)

#plot(
  data: d,
  mapping: aes(x: "quarter", y: "value"),
  layers: (geom-area(alpha: 0.5),),
  scales: (scale-x-discrete(),),
  labels: labels(title: "geom-area over a discrete x axis"),
  theme: theme-minimal(),
  width: 10cm,
  height: 6cm,
)
