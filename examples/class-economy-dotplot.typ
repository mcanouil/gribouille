// Showcase: sorted Cleveland dot plot of median highway economy per class.
// Dots over bars for point estimates; categories ordered by value, no legend.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)

#let by-class = summarise(
  mpg,
  hwy-med: rows => median(rows.map(row => row.hwy)).y,
  by: "class",
).sorted(key: row => row.hwy-med)

#plot(
  data: by-class,
  mapping: aes(x: "hwy-med", y: "class"),
  layers: (
    geom-point(size: 4pt, fill: accent),
  ),
  scales: scales(
    x: scale-continuous(limits: (10, 35)),
    y: scale-discrete(limits: by-class.map(row => row.class)),
  ),
  labels: labels(
    title: "Pickups and SUVs trail every car class on fuel economy",
    subtitle: "Median highway miles per gallon by vehicle class",
    x: "Median highway mpg",
    y: none,
    caption: "Source: bundled mpg dataset.",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 7cm,
)
