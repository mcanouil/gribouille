// Bundled penguins dataset: flipper length vs body mass by species.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let species-colours = (
  Adelie: rgb("#ff8c00"),
  Chinstrap: rgb("#008B8B"),
  Gentoo: rgb("#800080"),
)

#plot(
  data: penguins,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    colour: "species",
    fill: "species",
    shape: "species",
  ),
  layers: (
    geom-point(size: 2pt, alpha: 0.25, stroke: 0.5pt, colour: rgb("#ffffff")),
    geom-smooth(method: "lm", se: true, alpha: 0.2),
    geom-mark(method: "hull", expand: 5pt, alpha: 0.25),
    geom-errorbar(stat: stat-summary(fun: "mean-sd"), width: 5pt),
    geom-errorbarh(stat: stat-summary(fun: "mean-sd"), height: 5pt),
    geom-label(
      stat: stat-summary(fun: "mean"),
      mapping: aes(label: "species"),
      colour: rgb("#ffffff"),
      size: 8pt,
    ),
  ),
  scales: scales(x: scale-continuous(), y: scale-continuous(labels: format-comma()), colour: scale-discrete(limits: species-colours.keys(),
      palette: species-colours.values(),), fill: scale-discrete(limits: species-colours.keys(),
      palette: species-colours.values(),)),
  labels: labels(
    title: typst("Penguins *Dataset*"),
    subtitle: typst({
      [Flipper length vs body mass by species: ]
      species-colours
        .pairs()
        .map(p => text(fill: p.at(1), weight: "bold")[#p.at(0)])
        .join(", ")
    }),
    caption: "Data from Palmer Archipelago (Antarctica) penguin dataset.",
    colour: "Species",
    fill: "Species",
    shape: "Species",
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
