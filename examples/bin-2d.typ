// Two-dimensional rectangular binning. Every (x, y) sample is dropped into a
// uniform grid; cell counts colour the rectangles via the fill scale.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = 600
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
  layers: (geom-bin-2d(bins: 25),),
  scales: scales(fill: scale-viridis-c(option: "magma")),
  labels: labels(
    title: "Spiral Cloud Binned into a 25-by-25 Grid",
    subtitle: "Cells coloured by count, empty bins suppressed",
    fill: "count",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
