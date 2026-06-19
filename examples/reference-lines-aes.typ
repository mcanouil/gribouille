// Data-driven reference lines: bind the intercept channels through `aes()` so
// each row of an annotations frame draws its own line, coloured per row.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let df = range(0, 20).map(i => (x: i, y: 2 * i + 3 + calc.sin(i) * 2))

#let events = (
  (at: 5, grp: "start"),
  (at: 12, grp: "peak"),
  (at: 17, grp: "end"),
)

#let bands = (
  (lo: 15, lvl: "low"),
  (lo: 30, lvl: "high"),
)

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 2.5pt, alpha: 0.85),
    geom-vline(mapping: aes(xintercept: "at", colour: "grp"), data: events),
    geom-hline(
      mapping: aes(yintercept: "lo", colour: "lvl"),
      data: bands,
      linetype: "dashed",
    ),
  ),
  labels: labels(
    title: "Data-Driven Reference Lines",
    subtitle: "vline and hline read intercepts and colour from mapped columns",
    x: "X",
    y: "Y",
    colour: "Marker",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
