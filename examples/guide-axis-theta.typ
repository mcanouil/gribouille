// guide-axis-theta customises the angular axis under coord-radial: rotate
// theta tick labels, emit minor ticks at half-step positions, and draw an
// outer axis arc that respects the active theta range. The arc reads the
// `axis-line` theme surface and the ticks read `axis-ticks`, both of which
// theme-minimal blanks, so the panels below turn them back on.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let scores = (8, 6, 7, 9, 5, 8)
#let car = range(scores.len()).map(i => (axis: i, score: scores.at(i)))

#let ringed = theme-minimal(
  axis-line: element-line(stroke: 0.5pt),
  axis-ticks: element-tick(length: 0.15cm),
)

#let make-panel(title, gs, theme: ringed) = plot(
  data: car,
  mapping: aes(x: "axis", y: "score"),
  layers: (
    geom-polygon(fill: rgb("#1f77b4"), alpha: 0.4, stroke: 0.8pt),
    geom-point(size: 2pt),
  ),
  coord: coord-radial(theta: "x"),
  scales: scales(
    x: scale-continuous(
      limits: (0, 6),
      labels: v => if v == 6 { none } else { str(v) },
      expand: false,
    ),
    y: scale-continuous(limits: (0, 10)),
  ),
  guides: gs,
  labels: labels(title: title),
  theme: theme,
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  make-panel("theme-minimal(): spokes only", (:), theme: theme-minimal()),
  make-panel("axis-ticks: element-tick(length: 0.15cm)", (:)),
  make-panel("guide-axis-theta(minor-ticks: true)", guides(
    theta: guide-axis-theta(minor-ticks: true),
  )),
  make-panel("guide-axis-theta(angle: 30, cap: \"both\")", guides(
    theta: guide-axis-theta(angle: 30, cap: "both"),
  )),
)
