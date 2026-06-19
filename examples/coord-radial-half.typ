// Partial radial sweep: `end: π` keeps the panel as a half-circle so the
// domain endpoints render at distinct angles instead of stacking.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let scores = range(0, 13).map(i => (
  hour: i,
  load: 30 + 20 * calc.sin(calc.pi * i / 12) + calc.rem(i * 5, 7),
))

#plot(
  data: scores,
  mapping: aes(x: "hour", y: "load"),
  layers: (
    geom-line(stroke: 1pt),
    geom-point(size: 2pt),
  ),
  coord: coord-radial(theta: "x", end: calc.pi),
  scales: (
    scale-x-continuous(limits: (0, 12), expand: false),
  ),
  labels: labels(title: "Half-Day Load"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
