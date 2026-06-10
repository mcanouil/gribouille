// coord-flip swaps x and y so vertical bars read as horizontal.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let revenue = (
  (q: "Q1", revenue: 10),
  (q: "Q2", revenue: 18),
  (q: "Q3", revenue: 25),
  (q: "Q4", revenue: 22),
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: revenue,
    mapping: aes(x: "q", y: "revenue", fill: "q"),
    layers: (geom-col(),),
    guides: guides(fill: none),
    scales: (
      scale-y-continuous(labels: format-currency(symbol: "$", digits: 0)),
    ),
    labs: labs(
      title: "Default Cartesian",
      x: "Quarter",
      y: "Revenue (M)",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: revenue,
    mapping: aes(x: "q", y: "revenue", fill: "q"),
    layers: (geom-col(),),
    coord: coord-flip(),
    guides: guides(fill: none),
    scales: (
      scale-y-continuous(labels: format-currency(symbol: "$", digits: 0)),
    ),
    labs: labs(title: "coord-flip()", x: "Quarter", y: "Revenue (M)"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
