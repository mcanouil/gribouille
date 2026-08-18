// Filled bars: each quarter's total normalised to 1 (product share).

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
  layers: (geom-col(position: "fill"),),
  scales: scales(y: scale-continuous(labels: format-percent(),)),
  labels: labels(
    title: "Product Share of Revenue per Quarter",
    subtitle: "position-fill normalises each quarter total to 100%",
    x: "Quarter",
    y: "Share",
    fill: "Product",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
