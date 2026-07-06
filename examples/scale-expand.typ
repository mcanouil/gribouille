// scale-*-continuous(expand:) and coord-cartesian(expand: false) tune
// the breathing room around the data.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let pts = range(1, 11).map(i => (x: i, y: i))

#let base(title, scales: (:), coord-arg: none) = plot(
  data: pts,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 2.5pt, fill: rgb("#1f77b4")),),
  scales: scales,
  coord: coord-arg,
  labels: labels(title: title, x: "X", y: "Y"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  base("default (5% expand)"),
  base(
    "expand: false",
    scales: scales(x: scale-continuous(expand: false), y: scale-continuous(expand: false)),
  ),
  base(
    "coord-cartesian(expand: false)",
    coord-arg: coord-cartesian(expand: false),
  ),
)
