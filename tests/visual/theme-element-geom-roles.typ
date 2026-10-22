// Smoke render: element-geom role colours flow into every supporting geom.
// `ink` retints stroke/text and the bar tint's dark stop; `paper` retints
// boxplot/point/label fills and the tint's light stop; `accent` retints
// geom-smooth.

#import "../../lib.typ": *

#let d = range(0, 20).map(i => (
  x: i,
  y: i * 0.5 + calc.sin(i * 0.5) * 2,
))

#let bd = ()
#for (g, vals) in (
  ("a", (1, 2, 2, 3, 3, 4, 5, 6)),
  ("b", (3, 4, 5, 6, 6, 7, 7, 8)),
) {
  for v in vals { bd.push((g: g, y: v)) }
}

#let bars = (("Q1", 10), ("Q2", 18), ("Q3", 25), ("Q4", 22)).map(((q, r)) => (
  q: q,
  r: r,
))

#let roles-theme = theme(geom: element-geom(
  ink: rgb("#2c3e50"),
  paper: rgb("#fff7e6"),
  accent: rgb("#cc6600"),
))

#plot(
  data: bars,
  mapping: aes(x: "q", y: "r"),
  layers: (geom-col(),),
  theme: roles-theme,
  width: 8cm,
  height: 4cm,
)

#plot(
  data: bd,
  mapping: aes(x: "g", y: "y"),
  layers: (geom-boxplot(),),
  theme: roles-theme,
  width: 8cm,
  height: 4cm,
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt), geom-smooth(se: false)),
  theme: roles-theme,
  width: 8cm,
  height: 4cm,
)
