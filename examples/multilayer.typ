// Line plus point layers sharing a discrete colour mapping.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

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
  mapping: aes(x: "month", y: "sales", colour: "region"),
  layers: (
    geom-line(stroke: 1pt),
    geom-point(size: 3pt),
  ),
  scales: (
    scale-x-continuous(name: "Month"),
    scale-y-continuous(name: "Sales"),
  ),
  width: 11cm,
  height: 7cm,
)
