// Showcase: Simpson's paradox in bill dimensions; the pooled trend (dashed)
// slopes down while every within-species trend slopes up.

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

#let bills = drop-na(penguins, "bill-len", "bill-dep")

#plot(
  data: bills,
  mapping: aes(
    x: "bill-len",
    y: "bill-dep",
    colour: "species",
    fill: "species",
  ),
  layers: (
    geom-smooth(
      inherit-aes: false,
      mapping: aes(x: "bill-len", y: "bill-dep"),
      method: "lm",
      se: false,
      linetype: (4pt, 3pt),
      colour: luma(50%),
    ),
    geom-point(size: 2.2pt, alpha: 0.45),
    geom-smooth(method: "lm", se: false, stroke: 1.4pt),
    geom-text(
      inherit-aes: false,
      data: ((x: 57, y: 15.2, note: "pooled trend"),),
      mapping: aes(x: "x", y: "y", label: "note"),
      size: 9pt,
      colour: luma(50%),
      anchor: "east",
    ),
  ),
  scales: scales(colour: species-scale, fill: species-scale),
  labels: labels(
    title: "The pooled trend reverses within every species",
    subtitle: typst({
      [Bill depth against bill length for ]
      species-colours
        .pairs()
        .map(pair => text(fill: pair.at(1), weight: "bold")[#pair.at(0)])
        .join([, ], last: [, and ])
    }),
    x: "Bill length (mm)",
    y: "Bill depth (mm)",
    caption: "Fit trends per group before trusting an aggregate. Source: bundled Palmer penguins dataset.",
  ),
  guides: guides(default: none),
  theme: theme-minimal(),
  width: 12cm,
  height: 8.5cm,
)
