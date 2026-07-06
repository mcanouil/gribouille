// Smoke render: a band over a discrete x axis.
//
// Before the discrete-scale fix the ribbon ran each x cell through
// `parse-number`, which returned `none` for a category, so every row was
// dropped and the panel rendered blank. The band must now span the four
// quarters in domain order, not alphabetical order.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (quarter: "Q1", lo: 2, hi: 5),
  (quarter: "Q2", lo: 3, hi: 7),
  (quarter: "Q3", lo: 1, hi: 6),
  (quarter: "Q4", lo: 4, hi: 8),
)

#plot(
  data: d,
  mapping: aes(x: "quarter", ymin: "lo", ymax: "hi"),
  layers: (geom-ribbon(alpha: 0.4),),
  scales: scales(x: scale-discrete()),
  labels: labels(title: "geom-ribbon over a discrete x axis"),
  theme: theme-minimal(),
  width: 10cm,
  height: 6cm,
)
