// Showcase used by docs/index.qmd: faceted penguins with a linear smoother.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = csv("penguins.csv", row-type: dictionary)

#plot(
  data: df,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    colour: "species",
  ),
  layers: (
    geom-point(size: 2pt),
    geom-smooth(method: "lm"),
  ),
  facet: facet-wrap("island"),
  theme: theme-minimal(),
)
