// Showcase: waffle of species shares; units stay countable where a pie would
// force angle comparison, and the subtitle carries the colour key.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let species-colours = (
  Adelie: okabe-ito.at(0),
  Chinstrap: okabe-ito.at(1),
  Gentoo: okabe-ito.at(2),
)

#let species-counts = count(penguins, "species", sort: true)

#let scaled = species-counts.map(row => (
  ..row,
  units: calc.round(row.n / 4),
))

#plot(
  data: scaled,
  mapping: aes(fill: "species", weight: "units"),
  layers: (geom-tile(stat: stat-waffle(rows: 6), width: 0.85, height: 0.85),),
  scales: scales(fill: scale-discrete(
    limits: species-colours.keys(),
    palette: species-colours.values(),
  )),
  labels: labels(
    title: "Almost half of all penguins measured are Adelie",
    subtitle: typst({
      [One square is four penguins: ]
      species-counts
        .map(row => text(
          fill: species-colours.at(row.species),
          weight: "bold",
        )[#row.species (#row.n)])
        .join([, ], last: [, and ])
    }),
    x: "",
    y: "",
    caption: "Source: bundled Palmer penguins dataset.",
  ),
  guides: guides(default: none, x: none, y: none),
  theme: theme-void(),
  width: 12cm,
  height: 6.5cm,
)
