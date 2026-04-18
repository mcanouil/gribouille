// theme() override: increase axis title size and switch the panel background.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = range(0, 12).map(i => (x: i, y: i * i * 0.1))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-line(colour: rgb("#d6604d")), geom-point(size: 3pt)),
  theme: theme(
    axis-title-size: 12pt,
    axis-text-size: 10pt,
    panel-fill: rgb("#f7f0e7"),
    grid-colour: rgb("#d9cfbf"),
  ),
  labs: labs(title: "theme() overrides", x: "Step", y: "y = 0.1 * x²"),
  width: 10cm,
  height: 7cm,
)
