// Two routings for Typst markup in annotations:
//   - annotate("typst", label: "...") — the typst geom always evaluates the label.
//   - annotate("text",  label: typst("...")) — the typst() tag forces evaluation.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")
#let alert = rgb("#d62728")

#let df = range(0, 11).map(i => (x: i, y: 4 + 2 * calc.sin(i * 0.7) + i * 0.15))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent, alpha: 0.5),
    geom-point(size: 3pt, fill: accent),
    annotate("vline", xintercept: 5, colour: alert, stroke: 0.8pt),
    annotate(
      "typst",
      x: 5,
      y: 6.5,
      label: "*peak* at $x = 5$",
      anchor: "west",
      nudge-y: 0.3cm,
      size: 10pt,
    ),
    annotate(
      "text",
      x: 0.4,
      y: 7.5,
      label: typst("Series _A_"),
      anchor: "west",
      size: 12pt,
    ),
  ),
  labels: labels(
    title: "Annotations Rendered as Typst Markup",
    x: "Index",
    y: "Value",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
