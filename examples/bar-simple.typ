// Simple bar chart with discrete x.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let fruits = (
  (fruit: "apple", count: 12),
  (fruit: "banana", count: 19),
  (fruit: "cherry", count: 7),
  (fruit: "date", count: 15),
)

#plot(
  data: fruits,
  mapping: aes(x: "fruit", y: "count", fill: "fruit"),
  layers: (geom-col(),),
  guides: guides(fill: none),
  labs: labs(title: "Counts per Fruit", x: "Fruit", y: "Count"),
  theme: theme-grey(),
  width: 12cm,
  height: 9cm,
)
