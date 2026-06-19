// `stage(start, after-scale)` lets the colour aesthetic train on the
// same column the fill scale uses, then transparentise the resolved
// colour palette swatch as the marker outline. The `start` column
// drives initial training; the `after-scale` closure runs per row
// after the colour scale resolves the source.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 2, sp: "a"),
  (x: 2, y: 4, sp: "b"),
  (x: 3, y: 3, sp: "c"),
  (x: 4, y: 5, sp: "a"),
  (x: 5, y: 4, sp: "b"),
  (x: 6, y: 6, sp: "c"),
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    fill: "sp",
    colour: stage(
      start: "sp",
      after-scale: (c, _) => c.darken(40%),
    ),
  ),
  layers: (geom-point(size: 5pt, stroke: 0.8pt),),
  labels: labels(
    title: "Outline Trained on `Sp`, Darkened via Stage",
    fill: "Group",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
