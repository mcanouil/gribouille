// stat-align resamples each group onto a shared x-grid so stacked areas
// share clean vertices even when the inputs use mismatched x values.
// Side by side: the raw `stat: "identity"` overlap versus the aligned stack.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 0, y: 1, k: "a"),
  (x: 2, y: 3, k: "a"),
  (x: 4, y: 2, k: "a"),
  (x: 6, y: 1, k: "a"),
  (x: 1, y: 2, k: "b"),
  (x: 3, y: 1, k: "b"),
  (x: 5, y: 3, k: "b"),
  (x: 7, y: 2, k: "b"),
)

#let panel(stat, subtitle) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", fill: "k"),
  layers: (geom-area(stat: stat, alpha: 0.7),),
  labels: labels(subtitle: subtitle),
  theme: theme-minimal(),
  width: 12cm,
  height: 8cm,
)

#grid(
  columns: 1,
  row-gutter: 1em,
  panel("identity", "stat: \"identity\" (groups overlap)"),
  panel("align", "stat: \"align\" (shared x-grid)"),
)
