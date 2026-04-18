// Reference lines: hline, vline and abline overlaid on a scatter plot.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = range(0, 20).map(i => (x: i, y: 2 * i + 3 + calc.sin(i) * 2))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 3pt),
    geom-abline(slope: 2, intercept: 3, colour: rgb("#d62728")),
    geom-hline(yintercept: 20, colour: rgb("#2ca02c")),
    geom-vline(xintercept: 10, colour: rgb("#1f77b4")),
  ),
  labs: labs(title: "Trend with reference lines"),
  width: 10cm,
  height: 7cm,
)
