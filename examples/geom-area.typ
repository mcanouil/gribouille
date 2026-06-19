// geom-area: filled polygon from y = 0 up to y along x.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: economics,
  mapping: aes(x: "date", y: "unemploy"),
  layers: (
    geom-area(alpha: 0.35, fill: rgb("#1f77b4")),
    geom-line(stroke: 1pt, colour: rgb("#1f77b4")),
  ),
  scales: (
    scale-x-date(),
    scale-y-continuous(labels: format-comma()),
  ),
  labels: labels(
    title: "Monthly US Unemployment, 2008-2009",
    subtitle: "Area under the curve highlights the climb during the recession",
    x: "Month",
    y: "Unemployed (thousands)",
    caption: "Source: bundled economics dataset",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
