// Penguins dataset loaded from CSV: flipper length vs body mass by species.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let penguins = csv("penguins.csv", row-type: dictionary)

#plot(
  data: penguins,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    colour: "species",
  ),
  layers: (
    geom-point(size: 2pt),
  ),
  scales: (
    scale-x-continuous(name: "Flipper length (mm)"),
    scale-y-continuous(name: "Body mass (g)"),
  ),
  width: 11cm,
  height: 7cm,
)
