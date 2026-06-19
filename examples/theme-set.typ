// theme-set installs a global default once; subsequent plots inherit it
// unless they pass an explicit `theme:` argument.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#theme-set(theme-minimal())

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: penguins,
    mapping: aes(x: "flipper-len", y: "body-mass", colour: "species"),
    layers: (geom-point(size: 2pt, alpha: 0.85),),
    scales: (scale-y-continuous(labels: format-comma()),),
    labels: labels(
      title: "Inherits the Global Theme-Minimal",
      x: "Flipper Length (mm)",
      y: "Body Mass (g)",
      colour: "Species",
    ),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: penguins,
    mapping: aes(x: "flipper-len", y: "body-mass", colour: "species"),
    layers: (geom-point(size: 2pt, alpha: 0.85),),
    scales: (scale-y-continuous(labels: format-comma()),),
    labels: labels(
      title: "Explicit Theme-Dark Overrides the Global",
      x: "Flipper Length (mm)",
      y: "Body Mass (g)",
      colour: "Species",
    ),
    theme: theme-dark(),
    width: 12cm,
    height: 9cm,
  ),
)
