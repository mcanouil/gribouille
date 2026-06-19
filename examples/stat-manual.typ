// stat-manual lets you splice an ad-hoc closure into the layer pipeline.
// Here it adds a per-row index column, drawn as text labels.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 2),
  (x: 2, y: 4),
  (x: 3, y: 3),
  (x: 4, y: 6),
  (x: 5, y: 5),
)

#let with-index = data => (
  data
    .enumerate()
    .map(((i, r)) => (
      r
        + (
          label: "#" + str(i + 1),
        )
    ))
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 0.6pt, colour: rgb("#888")),
    geom-point(size: 4pt, colour: rgb("#cc3333")),
    geom-text(
      mapping: aes(label: "label", nudge-y: 0.4cm),
      stat: stat-manual(fun: with-index),
      size: 9pt,
    ),
  ),
  labels: labels(title: "Stat-Manual: per-Row Index Labels", x: "X", y: "Y"),
  theme: theme-minimal(),
  width: 12cm,
  height: 8cm,
)
