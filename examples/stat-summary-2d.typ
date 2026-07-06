// Reduce a `z` aesthetic over a 2D grid: each cell colours by the mean of
// the values that fell inside it, instead of the cell count.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = 600
#let d = range(0, n).map(i => {
  let t = i / n
  let theta = t * 6 * calc.pi
  let r = 1 + t * 3
  let x = r * calc.cos(theta) + calc.sin(t * 11.0) * 0.3
  let y = r * calc.sin(theta) + calc.cos(t * 13.0) * 0.3
  (x: x, y: y, z: r)
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", z: "z"),
  layers: (geom-rect(stat: stat-summary-2d(fun: "mean", bins: 25)),),
  scales: scales(fill: scale-viridis-c()),
  labels: labels(
    title: "Mean Radius Reduced over a 25-by-25 Grid",
    fill: "mean(r)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
