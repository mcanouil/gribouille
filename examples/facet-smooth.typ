// Facet-wrap with a per-panel smoother fitted only on each panel's subset.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (
    geom-point(size: 2.5pt, alpha: 0.85, colour: accent),
    geom-smooth(method: "lm", colour: accent, fill: accent, alpha: 0.2),
  ),
  facet: facet-wrap("cyl", ncolumn: 3, labeller: label-both()),
  labels: labels(
    title: "Per-Panel Linear Smoother",
    subtitle: "Each fit follows only the rows in its own panel",
    x: "Displacement (L)",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
