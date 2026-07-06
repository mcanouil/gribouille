// Showcase used by docs/index.qmd: faceted penguins with a linear smoother.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: penguins,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    colour: "species",
    fill: "species",
  ),
  layers: (
    geom-point(size: 2pt, alpha: 0.65),
    geom-smooth(method: "lm", alpha: 0.2),
  ),
  facet: facet-wrap("island", labeller: label-both()),
  scales: scales(y: scale-continuous(labels: format-comma())),
  labels: labels(
    title: "Penguin Morphology by Island",
    subtitle: "Flipper length versus body mass with a per-species linear fit",
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
    colour: "Species",
    fill: "Species",
  ),
  theme: theme-minimal(legend-position: bottom + right,),
  width: 12cm,
  height: 9cm,
)
