// Showcase: ridgeline of bill length per species; stacked densities read as
// small multiples of the same distribution without a shared-legend detour.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let species-colours = (
  Adelie: okabe-ito.at(0),
  Chinstrap: okabe-ito.at(1),
  Gentoo: okabe-ito.at(2),
)

#plot(
  data: drop-na(penguins, "bill-len"),
  mapping: aes(x: "bill-len", y: "species", fill: "species"),
  layers: (
    geom-density-ridges(scale: 1.1, alpha: 0.6),
  ),
  scales: scales(
    y: scale-discrete(expand: (0%, 60%)),
    fill: scale-discrete(
      limits: species-colours.keys(),
      palette: species-colours.values(),
    )
  ),
  labels: labels(
    title: "Chinstrap and Gentoo bills overlap; Adelie bills stand apart",
    subtitle: "Bill length distribution per species",
    x: "Bill length (mm)",
    y: "",
    caption: "Source: bundled Palmer penguins dataset.",
  ),
  guides: guides(default: none),
  theme: theme-minimal(
    axis-ticks: element-tick(length: 0.12cm),
    panel-grid-major-y: element-line()
  ),
  width: 12cm,
  height: 7.5cm,
)
