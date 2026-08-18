// Dodged bars: products shown side-by-side per quarter.

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
  layers: (geom-col(position: "dodge"),),
  scales: scales(
    x: scale-discrete(expand: false),
    y: scale-continuous(
      expand: (0%, 10%),
        labels: format-currency(symbol: "$", digits: 0)
    )
  ),
  labels: labels(
    title: "Revenue by Quarter, Dodged",
    subtitle: "Side-by-side bars compare products within each quarter",
    x: "Quarter",
    y: "Revenue (M)",
    fill: "Product",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
