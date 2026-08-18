// Showcase: count heatmap with values printed in the cells; a single-hue
// sequential ramp encodes magnitude and the numbers remove the guesswork.
// The ramp stops at a mid tone so the fixed dark ink reads on every cell,
// including the palest; a full light-to-dark ramp would strand the labels.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let ink = rgb("#08306b")

#let cells = count(mpg, "class", "cyl")

#plot(
  data: cells,
  mapping: aes(x: as-factor("cyl"), y: "class", fill: "n"),
  layers: (
    geom-tile(width: 0.95, height: 0.95),
    geom-text(mapping: aes(label: "n"), size: 9pt, colour: ink),
  ),
  scales: scales(
    fill: scale-gradient(low: rgb("#eff6fb"), high: rgb("#9ecae1")),
  ),
  labels: labels(
    title: "Four-cylinder compacts are the most common combination",
    subtitle: "Number of vehicles per class and cylinder count",
    x: "Cylinders",
    y: none,
    caption: "Source: bundled mpg dataset.",
  ),
  guides: guides(default: none),
  theme: theme-minimal(axis-ticks: element-tick(length: 0.12cm)),
  width: 12cm,
  height: 7.5cm,
)
