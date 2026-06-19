// guide-axis-theta customises the angular axis under coord-radial: rotate
// theta tick labels, emit minor ticks at half-step positions, and draw an
// outer axis arc that respects the active theta range.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let scores = (8, 6, 7, 9, 5, 8)
#let car = range(scores.len()).map(i => (axis: i, score: scores.at(i)))

#let make-panel(title, gs) = plot(
  data: car,
  mapping: aes(x: "axis", y: "score"),
  layers: (
    geom-polygon(fill: rgb("#1f77b4"), alpha: 0.4, stroke: 0.8pt),
    geom-point(size: 2pt),
  ),
  coord: coord-radial(theta: "x"),
  scales: (
    scale-x-continuous(
      limits: (0, 6),
      labels: v => if v == 6 { none } else { str(v) },
      expand: false,
    ),
    scale-y-continuous(limits: (0, 10)),
  ),
  guides: gs,
  labels: labels(title: title),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  make-panel("Default radial axis", (:)),
  make-panel("guide-axis-theta(minor-ticks: true)", guides(
    theta: guide-axis-theta(minor-ticks: true),
  )),
  make-panel("guide-axis-theta(angle: 30, cap: \"both\")", guides(
    theta: guide-axis-theta(angle: 30, cap: "both"),
  )),
)
