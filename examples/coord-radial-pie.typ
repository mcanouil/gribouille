// coord-radial(theta: "y") + geom-col + position-stack produces a pie chart.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let revenue = (
  (slice: "all", value: 30, region: "EU"),
  (slice: "all", value: 22, region: "US"),
  (slice: "all", value: 18, region: "APAC"),
  (slice: "all", value: 12, region: "LATAM"),
  (slice: "all", value: 18, region: "Other"),
)

#plot(
  data: revenue,
  mapping: aes(x: "slice", y: "value", fill: "region"),
  layers: (geom-col(width: 1, position: "stack"),),
  coord: coord-radial(theta: "y"),
  scales: (scale-y-continuous(expand: false),),
  labels: labels(title: "Revenue Share", fill: "Region"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
