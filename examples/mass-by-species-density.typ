// Showcase: overlaid body-mass densities per species, labelled in the
// subtitle instead of a legend; translucent fills keep every curve readable.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let species-colours = (
  Adelie: okabe-ito.at(0),
  Chinstrap: okabe-ito.at(1),
  Gentoo: okabe-ito.at(2),
)

#let species-scale = scale-discrete(
  limits: species-colours.keys(),
  palette: species-colours.values(),
)

#plot(
  data: drop-na(penguins, "body-mass"),
  mapping: aes(x: "body-mass", colour: "species", fill: "species"),
  layers: (
    geom-density(fill: auto, alpha: 0.35, stroke: 1pt),
  ),
  scales: scales(
    x: scale-continuous(labels: format-comma()),
    colour: species-scale,
    fill: species-scale,
  ),
  labels: labels(
    title: "Gentoo penguins are in a weight class of their own",
    subtitle: typst({
      [Body-mass distribution for ]
      species-colours
        .pairs()
        .map(pair => text(fill: pair.at(1), weight: "bold")[#pair.at(0)])
        .join([, ], last: [, and ])
    }),
    x: "Body mass (g)",
    y: "Density",
    caption: "Source: bundled Palmer penguins dataset.",
  ),
  guides: guides(default: none),
  theme: theme-minimal()
    + theme-sub-axis-y(text: element-blank(), ticks: element-blank()),
  width: 12cm,
  height: 7cm,
)
