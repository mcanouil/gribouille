// Rose chart: discrete categories distributed around the circle, height as r.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let counts = (
  (dir: "N", count: 12),
  (dir: "NE", count: 9),
  (dir: "E", count: 5),
  (dir: "SE", count: 4),
  (dir: "S", count: 7),
  (dir: "SW", count: 11),
  (dir: "W", count: 14),
  (dir: "NW", count: 10),
)

#plot(
  data: counts,
  mapping: aes(x: "dir", y: "count", fill: "dir"),
  layers: (geom-col(width: 1),),
  coord: coord-radial(theta: "x"),
  scales: scales(x: scale-discrete(expand: false)),
  guides: guides(fill: none),
  labels: labels(title: "Wind Directions"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
