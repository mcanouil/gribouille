// Scatter with an OLS smoother and 95% CI band.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (
    geom-point(size: 2.5pt, alpha: 0.75, colour: accent),
    geom-smooth(method: "lm", colour: accent, fill: accent, alpha: 0.2),
  ),
  labels: labels(
    title: "Engine Displacement Versus Highway Fuel Economy",
    subtitle: "Linear fit with 95% confidence band",
    x: "Displacement (L)",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
