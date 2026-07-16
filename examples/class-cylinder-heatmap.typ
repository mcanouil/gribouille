// Showcase: count heatmap with values printed in the cells; a single-hue
// sequential ramp encodes magnitude and the numbers remove the guesswork.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let cells = count(mpg, "class", "cyl")

#plot(
  data: cells,
  mapping: aes(x: as-factor("cyl"), y: "class", fill: "n"),
  layers: (
    geom-tile(width: 0.95, height: 0.95),
    geom-text(mapping: aes(label: "n"), size: 9pt, colour: rgb("#ffffff")),
  ),
  scales: scales(
    fill: scale-gradient(low: rgb("#c6dbef"), high: rgb("#08306b")),
  ),
  labels: labels(
    title: "Four-cylinder compacts are the most common combination",
    subtitle: "Number of vehicles per class and cylinder count",
    x: "Cylinders",
    y: "",
    caption: "Source: bundled mpg dataset.",
  ),
  guides: guides(default: none),
  theme: theme-minimal(),
  width: 12cm,
  height: 7.5cm,
)
