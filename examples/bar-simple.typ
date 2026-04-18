// Simple bar chart with discrete x.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let fruits = (
  (fruit: "apple", count: 12),
  (fruit: "banana", count: 19),
  (fruit: "cherry", count: 7),
  (fruit: "date", count: 15),
)

#plot(
  data: fruits,
  mapping: aes(x: "fruit", y: "count", fill: "fruit"),
  layers: (
    geom-col(),
  ),
  scales: (
    scale-x-discrete(name: "Fruit"),
    scale-y-continuous(name: "Count"),
  ),
  width: 10cm,
  height: 7cm,
)
