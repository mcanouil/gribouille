// coord-fixed locks the panel so one x unit equals `ratio` y units.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")
#let df = range(0, 11).map(i => (x: i, y: i))

#let panel(title, coord-arg) = plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent),
    geom-point(size: 2pt, fill: accent),
  ),
  coord: coord-arg,
  labels: labels(title: title, x: "X", y: "Y"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  panel("Default cartesian (panel ratio)", none),
  panel("coord-fixed(ratio: 1) — square units", coord-fixed(ratio: 1)),
)
