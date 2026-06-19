// Family-scoped shortcuts compose with theme-minimal() via `+`.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (q: "Q1", revenue: 12, segment: "Retail"),
  (q: "Q2", revenue: 18, segment: "Retail"),
  (q: "Q3", revenue: 25, segment: "Retail"),
  (q: "Q4", revenue: 22, segment: "Retail"),
  (q: "Q1", revenue: 8, segment: "Online"),
  (q: "Q2", revenue: 15, segment: "Online"),
  (q: "Q3", revenue: 20, segment: "Online"),
  (q: "Q4", revenue: 28, segment: "Online"),
)

#plot(
  data: d,
  mapping: aes(x: "q", y: "revenue", fill: "segment"),
  layers: (geom-col(position: "dodge"),),
  labels: labels(
    title: "Quarterly Revenue by Segment",
    x: "Quarter",
    y: "Revenue (m£)",
    fill: "Segment",
  ),
  theme: theme-minimal()
    + theme-sub-axis(
      text: element-text(size: 9pt, colour: rgb("#444")),
      title: element-text(size: 10pt, weight: "bold"),
    )
    + theme-sub-legend(
      title: element-text(weight: "bold"),
      text: element-text(size: 8pt),
    )
    + theme-sub-plot(title: element-text(size: 13pt, weight: "bold")),
  width: 12cm,
  height: 9cm,
)
