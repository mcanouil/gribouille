// scale-manual and scale-manual: user-supplied palettes.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let palette = (rgb("#ff8c00"), rgb("#800080"), rgb("#008B8B"))

#plot(
  data: penguins,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    colour: "species",
    fill: "species",
  ),
  layers: (
    geom-point(size: 2pt, alpha: 0.7),
    geom-smooth(method: "lm", alpha: 0.15),
  ),
  scales: scales(colour: scale-manual(values: palette), fill: scale-manual(values: palette), y: scale-continuous(labels: format-comma())),
  labels: labels(
    title: "Penguin Species Drawn with a Custom Palette",
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
    colour: "Species",
    fill: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
