// geom-bar: counts observations per category.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let items = (
  (cat: "A",), (cat: "A",), (cat: "A",),
  (cat: "B",), (cat: "B",),
  (cat: "C",), (cat: "C",), (cat: "C",), (cat: "C",),
  (cat: "D",), (cat: "D",), (cat: "D",), (cat: "D",), (cat: "D",),
)

#plot(
  data: items,
  mapping: aes(x: "cat"),
  layers: (geom-bar(),),
  labs: labs(title: "Category counts", x: "Category", y: "Count"),
  width: 10cm,
  height: 7cm,
)
