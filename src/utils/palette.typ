// Default colour palettes.
// Discrete defaults avoid purple-ish hues.

#let default-discrete = (
  rgb("#1f77b4"),
  rgb("#2ca02c"),
  rgb("#d62728"),
  rgb("#ff7f0e"),
  rgb("#17becf"),
  rgb("#8c564b"),
  rgb("#e377c2"),
  rgb("#7f7f7f"),
)

// Shape palette: keywords resolved by geom-point's `_draw-shape`.
// Covers the most common ggplot2 shape indices without overlap.
#let default-shapes = (
  "circle",
  "square",
  "triangle",
  "diamond",
  "cross",
  "x",
  "star",
  "triangle-down",
)

// Linetype palette: dash patterns accepted by CeTZ stroke `dash` keyword.
#let default-linetypes = (
  "solid",
  "dashed",
  "dotted",
  "dash-dotted",
  "densely-dashed",
  "loosely-dashed",
)
