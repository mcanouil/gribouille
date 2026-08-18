// Smoke render: theta tick marks under coord-radial. Read each panel for the
// mark placement the unit tests cannot assert: majors land on the breaks and
// point outward, minors bisect every gap including the wrap one on a full
// turn, a capped arc end carries no major tick, and a pie reads both weights
// off its `y` scale.

#import "../../lib.typ": *

#let d = range(0, 6).map(i => (k: i, v: 4 + calc.rem(i * 3, 5)))

#let ringed = theme-minimal(
  axis-line: element-line(stroke: 0.5pt),
  axis-ticks: element-tick(length: 0.3cm),
)

#let panel(title, theta: "x", guides: guides(), coord: coord-radial()) = plot(
  data: d,
  mapping: aes(x: "k", y: "v"),
  layers: (geom-point(size: 2pt),),
  coord: coord,
  scales: scales(x: scale-continuous(
    limits: (0, 6),
    expand: false,
    labels: v => if v == 6 { none } else { str(v) },
  )),
  guides: guides,
  labels: labels(title: title),
  theme: ringed,
  width: 8cm,
  height: 7cm,
)

#grid(
  columns: 2,
  row-gutter: 0.4cm,
  column-gutter: 0.4cm,
  panel("Majors on the breaks, no guide bound"),
  panel(
    "Minors bisect every gap, wrap included",
    guides: guides(theta: guide-axis-theta(minor-ticks: true)),
  ),

  panel(
    "A capped end drops its major tick",
    guides: guides(theta: guide-axis-theta(cap: "both", minor-ticks: true)),
  ),
  plot(
    data: (
      (slice: "all", value: 5, part: "a"),
      (slice: "all", value: 3, part: "b"),
      (slice: "all", value: 2, part: "c"),
    ),
    mapping: aes(x: "slice", y: "value", fill: "part"),
    layers: (geom-col(width: 1, position: "stack"),),
    coord: coord-radial(theta: "y"),
    scales: scales(y: scale-continuous(expand: false)),
    guides: guides(fill: none, theta: guide-axis-theta(minor-ticks: true)),
    labels: labels(title: "A pie reads both weights off y"),
    theme: ringed,
    width: 8cm,
    height: 7cm,
  ),
)
