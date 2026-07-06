// Long-tail geoms: blank, rug, function across three panels.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let p1 = plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", colour: "class"),
  layers: (
    geom-point(size: 2.5pt, alpha: 0.85),
    geom-rug(sides: "bl"),
  ),
  labels: labels(
    title: "Geom-Rug for Marginal Observations",
    x: "Displacement (L)",
    y: "Highway mpg",
    colour: "Class",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#let frame = ((x: -calc.pi, y: -1), (x: calc.pi, y: 1))

#let p2 = plot(
  data: frame,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-blank(),
    geom-function(
      fun: x => calc.sin(x),
      x-limits: (-calc.pi, calc.pi),
      colour: rgb("#d62728"),
      stroke: 1.2pt,
    ),
  ),
  scales: scales(x: scale-continuous(breaks: (-3, -1.5, 0, 1.5, 3))),
  labels: labels(
    title: "Geom-Blank as a Frame for Geom-Function",
    x: "X",
    y: "sin(x)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#let p3 = plot(
  data: mpg,
  mapping: aes(x: "hwy"),
  layers: (
    geom-blank(
      data: ((x: 10, y: 0), (x: 50, y: 1)),
      mapping: aes(x: "x", y: "y"),
      inherit-aes: false,
    ),
    geom-rug(sides: "b", colour: rgb("#2ca02c"), length: 0.4cm),
  ),
  scales: scales(x: scale-continuous(name: "Highway mpg")),
  labels: labels(title: "Forced X-Range to Highlight Rug Density", y: ""),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  p1,
  p2,
  p3,
)
