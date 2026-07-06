// Stacked bars: quarters on x, revenue by product stacked within each quarter.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

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
  scales: scales(y: scale-continuous(labels: format-currency(symbol: "$", digits: 0))),
  labels: labels(
    title: "Revenue by Quarter",
    subtitle: "Stacked bars highlight per-quarter totals",
    x: "Quarter",
    y: "Revenue (M)",
    fill: "Product",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
