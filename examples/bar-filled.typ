// Filled bars: each quarter's total normalised to 1 (product share).

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let sales = (
  (q: "Q1", product: "A", revenue: 10),
  (q: "Q1", product: "B", revenue: 20),
  (q: "Q1", product: "C", revenue: 15),
  (q: "Q2", product: "A", revenue: 12),
  (q: "Q2", product: "B", revenue: 18),
  (q: "Q2", product: "C", revenue: 22),
  (q: "Q3", product: "A", revenue: 8),
  (q: "Q3", product: "B", revenue: 25),
  (q: "Q3", product: "C", revenue: 30),
)

#plot(
  data: sales,
  mapping: aes(x: "q", y: "revenue", fill: "product"),
  layers: (geom-col(position: "fill"),),
  labs: labs(title: "Product share by quarter", x: "Quarter", y: "Share"),
  width: 10cm,
  height: 7cm,
)
