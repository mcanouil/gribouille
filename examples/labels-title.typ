// labels(): title, subtitle, caption, and axis labels in one call.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let df = range(1, 16).map(i => (x: i, y: i + calc.rem(i * 7, 5)))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: rgb("#1f77b4")),
    geom-point(size: 3pt, fill: rgb("#1f77b4")),
  ),
  labels: labels(
    title: "Monthly Counts",
    subtitle: "First half of the experiment",
    caption: "Source: simulated dataset.",
    x: "Month",
    y: "Count",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
