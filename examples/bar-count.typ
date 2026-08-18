// geom-bar: counts observations per category.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let items = (
  (cat: "A"),
  (cat: "A"),
  (cat: "A"),
  (cat: "B"),
  (cat: "B"),
  (cat: "C"),
  (cat: "C"),
  (cat: "C"),
  (cat: "C"),
  (cat: "D"),
  (cat: "D"),
  (cat: "D"),
  (cat: "D"),
  (cat: "D"),
)

#plot(
  data: items,
  mapping: aes(x: "cat", fill: "cat"),
  layers: (geom-bar(),),
  scales: scales(y: scale-continuous(expand: (0%, 20%))),
  guides: guides(fill: none),
  labels: labels(
    title: "Category Counts via Stat-Count",
    x: "Category",
    y: "Count",
  ),
  theme: theme-minimal(axis-ticks: element-tick(length: 0.12cm)),
  width: 12cm,
  height: 9cm,
)
