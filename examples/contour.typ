// Marching-squares contour lines on a regular (x, y, z) grid. Sampling a
// classic radial-wave field gives a clean ring of iso-lines.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = 60
#let d = ()
#for i in range(n) {
  for j in range(n) {
    let x = -3 + 6 * i / (n - 1)
    let y = -3 + 6 * j / (n - 1)
    let r = calc.sqrt(x * x + y * y)
    d.push((x: x, y: y, z: calc.sin(r * 2.5) * calc.exp(-r / 3)))
  }
}

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", z: "z", colour: "level"),
  layers: (geom-contour(bins: 12, stroke: 0.6pt),),
  scales: (scale-colour-viridis-c(option: "viridis"),),
  labels: labels(
    title: "Radial Wave: 12 Contour Levels",
    subtitle: "z = sin(2.5 r) · exp(-r / 3) over a 60-by-60 grid",
    colour: "level",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
