// Line plus point layers sharing discrete colour and fill mappings.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let trend = (
  (month: 1, sales: 12, region: "north"),
  (month: 2, sales: 15, region: "north"),
  (month: 3, sales: 14, region: "north"),
  (month: 4, sales: 18, region: "north"),
  (month: 5, sales: 22, region: "north"),
  (month: 6, sales: 25, region: "north"),
  (month: 1, sales: 8, region: "south"),
  (month: 2, sales: 11, region: "south"),
  (month: 3, sales: 13, region: "south"),
  (month: 4, sales: 12, region: "south"),
  (month: 5, sales: 16, region: "south"),
  (month: 6, sales: 20, region: "south"),
  (month: 1, sales: 5, region: "east"),
  (month: 2, sales: 7, region: "east"),
  (month: 3, sales: 9, region: "east"),
  (month: 4, sales: 12, region: "east"),
  (month: 5, sales: 14, region: "east"),
  (month: 6, sales: 17, region: "east"),
)

#plot(
  data: trend,
  mapping: aes(x: "month", y: "sales", colour: "region", fill: "region"),
  layers: (
    geom-line(stroke: 1pt),
    geom-point(size: 3pt),
  ),
  scales: (scale-x-continuous(breaks: (1, 2, 3, 4, 5, 6)),),
  labels: labels(
    title: "Monthly Sales by Region",
    subtitle: "Line and point layers share a single colour mapping",
    x: "Month",
    y: "Sales",
    colour: "Region",
    fill: "Region",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
