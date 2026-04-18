// coord-cartesian: zoom in via xlim/ylim without dropping rows.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = range(0, 25).map(i => (x: i, y: i * i))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-line(colour: rgb("#1f77b4")), geom-point(size: 2pt)),
  coord: coord-cartesian(xlim: (5, 15), ylim: (0, 250)),
  labs: labs(title: "coord-cartesian zoom"),
  width: 10cm,
  height: 7cm,
)
