// scale-date parses ISO date strings on x and renders year-month tick labels.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: economics,
  mapping: aes(x: "date", y: "psavert"),
  layers: (
    geom-line(stroke: 1.2pt, colour: rgb("#1f77b4")),
    geom-point(size: 2pt, fill: rgb("#1f77b4")),
  ),
  scales: scales(x: scale-date(date-format: "[year]-[month repr:numerical]")),
  labels: labels(
    title: "US Personal Savings Rate During the Recession",
    subtitle: "Monthly observations, 2008-2009",
    x: "Month",
    y: "Personal Savings Rate (%)",
    caption: "Source: bundled economics dataset",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
