// Reference lines on a log10 y axis: yintercept values land at the correct
// log positions because hline routes through the axis transform.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")
#let df = range(1, 11).map(i => (x: i, y: calc.pow(10, i / 3)))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent, alpha: 0.5),
    geom-point(size: 3pt, fill: accent),
    geom-hline(
      yintercept: (10, 100, 1000),
      colour: rgb("#d62728"),
      linetype: "dashed",
    ),
  ),
  scales: (scale-y-log10(labels: format-comma()),),
  labels: labels(
    title: "Reference Lines on a log10 Y Axis",
    subtitle: "yintercept = (10, 100, 1000) lands at the correct log positions",
    x: "X",
    y: "Y (log10)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
