// Hexagonal binning. Each (x, y) sample drops into a pointy-top hex cell;
// cells colour by count via the fill scale.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = 800
#let d = range(0, n).map(i => {
  let t = i / n
  let theta = t * 6 * calc.pi
  let r = 1 + t * 3 + calc.sin(theta * 2) * 0.4
  (
    x: r * calc.cos(theta) + calc.sin(t * 11.0) * 0.3,
    y: r * calc.sin(theta) + calc.cos(t * 13.0) * 0.3,
  )
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-hex(bins: 22),),
  scales: (scale-fill-viridis-c(option: "viridis"),),
  labels: labels(
    title: "Spiral Cloud Binned into Pointy-Top Hexagons",
    subtitle: "Cells coloured by count, empty bins suppressed",
    fill: "count",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
