// Mixed-width dodge: per-row `width` column makes one product wider than the others.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let sales = (
  (q: "Q1", product: "A", revenue: 10, width: 0.6),
  (q: "Q1", product: "B", revenue: 20, width: 0.4),
  (q: "Q2", product: "A", revenue: 12, width: 0.6),
  (q: "Q2", product: "B", revenue: 18, width: 0.4),
  (q: "Q3", product: "A", revenue: 8, width: 0.6),
  (q: "Q3", product: "B", revenue: 25, width: 0.4),
)

#plot(
  data: sales,
  mapping: aes(x: "q", y: "revenue", fill: "product"),
  layers: (geom-col(position: "dodge"),),
  scales: (
    scale-y-continuous(labels: format-currency(symbol: "$", digits: 0)),
  ),
  labels: labels(
    title: "Revenue with Mixed-Width Dodge Slots",
    subtitle: "Each row supplies its own dodge slot width via the width column",
    x: "Quarter",
    y: "Revenue (M)",
    fill: "Product",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
