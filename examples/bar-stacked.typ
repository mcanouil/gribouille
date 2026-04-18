// Stacked bars: quarters on x, revenue by product stacked within each quarter.

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
  layers: (geom-col(position: "stack"),),
  labs: labs(title: "Revenue by quarter", x: "Quarter", y: "Revenue (k$)"),
  width: 10cm,
  height: 7cm,
)
