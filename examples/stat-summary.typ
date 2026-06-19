// stat-summary collapses each x bucket to a summary statistic per layer.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#plot(
  data: mpg,
  mapping: aes(x: as-factor("cyl"), y: "hwy"),
  layers: (
    geom-jitter(
      size: 2pt,
      alpha: 0.4,
      colour: accent,
      position: position-jitter(width: 0.12),
    ),
    geom-errorbar(
      stat: stat-summary(fun: "mean-se", fun-args: (multiplier: 1)),
      width: 0.25,
      stroke: 1pt,
      colour: accent,
    ),
    geom-point(
      stat: stat-summary(fun: "mean-se", fun-args: (multiplier: 1)),
      size: 3.5pt,
      fill: accent,
    ),
  ),
  labels: labels(
    title: "Highway Fuel Economy by Cylinder Count",
    subtitle: "Mean ± 1 SE on top of the raw jittered observations",
    x: "Cylinders",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
