// Constant Typst content as a label, set directly on the layer.
//   - geom-typst(label: [...]) — content block applied to every row.
//   - annotate("typst", label: [...]) — content block on a single row.
// Both forms accept content directly; no `typst()` wrapper is needed.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")
#let alert = rgb("#d62728")

#let df = range(0, 7).map(i => (x: i, y: 2 + calc.cos(i * 0.6) + i * 0.3))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent, alpha: 0.5),
    geom-point(size: 3pt, fill: accent),
    geom-typst(mapping: aes(nudge-y: 0.4cm), label: [#math.star], size: 12pt, colour: accent),
    annotate(
      "typst",
      x: 3,
      y: 4.2,
      label: [*peak* at #math.alpha],
      colour: alert,
      anchor: "south",
      nudge-y: 0.2cm,
      size: 11pt,
    ),
  ),
  scales: scales(y: scale-continuous(expand: (5%, 20%))),
  labels: labels(
    title: "Constant Content Labels via Geom-Typst and Annotate",
    x: "Index",
    y: "Value",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
