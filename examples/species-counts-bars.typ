// Showcase: horizontal count bars with direct value labels; long category
// names stay readable and the labels replace a value axis.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(2)

#let species-counts = count(penguins, "species", sort: true)

#plot(
  data: species-counts,
  mapping: aes(x: "species", y: "n"),
  layers: (
    geom-col(fill: accent),
    geom-text(
      mapping: aes(label: "n"),
      nudge-x: 0.25cm,
      size: 9pt,
    ),
  ),
  scales: scales(
    x: scale-discrete(limits: species-counts.map(row => row.species)),
  ),
  coord: coord-flip(),
  labels: labels(
    title: "Adelie penguins dominate the sample",
    subtitle: "Penguins measured per species, 2007-2009",
    x: none,
    y: "Penguins measured",
    caption: "Source: bundled Palmer penguins dataset.",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 6cm,
)
