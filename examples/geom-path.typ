// geom-path: connects rows in input order, not sorted by x.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let spiral = ()
#for i in range(0, 60) {
  let t = i * 0.2
  let r = 3 + t * 0.05
  spiral.push((x: calc.cos(t) * r, y: calc.sin(t) * r, t: t))
}

#plot(
  data: spiral,
  mapping: aes(x: "x", y: "y", colour: "t"),
  layers: (geom-path(stroke: 1.2pt),),
  scales: (
    scale-colour-viridis-c(),
    scale-x-continuous(breaks: (-6, -3, 0, 3, 6)),
    scale-y-continuous(breaks: (-6, -3, 0, 3, 6)),
  ),
  coord: coord-fixed(),
  labels: labels(
    title: "Geom-Path Follows Row Order",
    subtitle: "Colour encodes traversal time along the spiral",
    x: "X",
    y: "Y",
    colour: "t",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
