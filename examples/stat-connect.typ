// stat-connect inserts intermediate vertices between consecutive points.
// Two layers compare "hv" (default, step) and "mid" (midpoint corner)
// connection modes against the same dataset.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(0, 8).map(i => (x: i, y: calc.rem(i * 3 + 2, 5)))

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-path(
      stat: stat-connect(connection: "hv"),
      stroke: 1pt,
      colour: rgb("#1f77b4"),
    ),
    geom-path(
      stat: stat-connect(connection: "mid"),
      stroke: 1pt,
      colour: rgb("#ff7f0e"),
    ),
    geom-point(size: 3pt),
  ),
  labels: labels(title: "Stat-Connect: Hv (blue) vs Mid (orange)"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
