// stat-function samples an analytic function and feeds the result into any geom.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let frame = ((x: -calc.pi, y: -1.2), (x: calc.pi, y: 1.2))

#plot(
  data: frame,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-blank(),
    geom-line(
      stat: stat-function(fun: x => calc.sin(x), x-limits: (-calc.pi, calc.pi)),
      colour: rgb("#1f77b4"),
      stroke: 1.2pt,
    ),
    geom-line(
      stat: stat-function(fun: x => calc.cos(x), x-limits: (-calc.pi, calc.pi)),
      colour: rgb("#d62728"),
      stroke: 1.2pt,
      linetype: "dashed",
    ),
  ),
  scales: (scale-x-continuous(breaks: (-3, -1.5, 0, 1.5, 3)),),
  labels: labels(
    title: "Two Analytic Curves over a Shared X-Range",
    subtitle: "stat-function samples each function across x-limits and routes the points to geom-line",
    x: "X",
    y: "f(x)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
