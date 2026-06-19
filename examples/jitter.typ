// geom-jitter spreads overlapping points so density per category is visible.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "class", y: "hwy", colour: "class"),
  layers: (
    geom-jitter(
      size: 2.5pt,
      alpha: 0.85,
      position: position-jitter(width: 0.25),
    ),
  ),
  scales: (
    scale-y-continuous(breaks: (15, 20, 25, 30, 35, 40)),
  ),
  guides: guides(colour: none),
  labels: labels(
    title: "Highway mpg per Vehicle Class",
    subtitle: "Jitter spreads coincident points so cluster density reads",
    x: "Class",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
