// Reference lines: hline, vline, and abline overlaid on a scatter plot.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let df = range(0, 20).map(i => (x: i, y: 2 * i + 3 + calc.sin(i) * 2))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 2.5pt, alpha: 0.85),
    geom-abline(slope: 2, intercept: 3, colour: rgb("#d62728")),
    geom-hline(yintercept: 20, colour: rgb("#2ca02c")),
    geom-vline(xintercept: 10, colour: rgb("#1f77b4")),
  ),
  labels: labels(
    title: "Trend with Reference Lines",
    subtitle: "abline, hline, and vline highlight expected values without joining the data",
    x: "X",
    y: "Y",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
