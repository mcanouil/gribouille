// coord-cartesian: zoom in via x-limits/y-limits without dropping rows.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")
#let df = range(0, 25).map(i => (x: i, y: i * i))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent),
    geom-point(size: 2pt, fill: accent),
  ),
  coord: coord-cartesian(x-limits: (5, 15), y-limits: (0, 250)),
  labels: labels(
    title: "Coord-Cartesian Zoom",
    subtitle: "x-limits and y-limits clip the view; rows outside the window stay in the data",
    x: "X",
    y: "Y",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
