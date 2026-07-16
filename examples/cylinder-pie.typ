// Showcase: a pie that earns its keep; three slices, directly keyed in the
// subtitle, no legend to shuttle between.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let cyl-colours = (
  "4": okabe-ito.at(0),
  "6": okabe-ito.at(1),
  "8": okabe-ito.at(2),
)

#let shares = count(mpg, "cyl").map(row => (
  slice: "all",
  cyl: str(row.cyl),
  n: row.n,
))

#plot(
  data: shares,
  mapping: aes(x: "slice", y: "n", fill: "cyl"),
  layers: (geom-col(width: 1, position: "stack"),),
  coord: coord-radial(theta: "y"),
  scales: scales(
    y: scale-continuous(expand: false),
    fill: scale-discrete(
      limits: cyl-colours.keys(),
      palette: cyl-colours.values(),
    ),
  ),
  labels: labels(
    title: "Four-cylinder engines power almost half the fleet",
    subtitle: typst({
      [Share of vehicles by cylinder count: ]
      shares
        .map(row => text(
          fill: cyl-colours.at(row.cyl),
          weight: "bold",
        )[#row.cyl cyl (#row.n)])
        .join([, ], last: [, and ])
    }),
    caption: "A pie works with a handful of labelled slices. Source: bundled mpg dataset.",
  ),
  guides: guides(default: none),
  theme: theme-void(),
  width: 12cm,
  height: 8cm,
)
