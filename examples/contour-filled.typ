#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = 50
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
  mapping: aes(x: "x", y: "y", z: "z"),
  layers: (geom-contour-filled(bins: 10),),
  scales: scales(fill: scale-viridis-c(option: "magma")),
  labels: labels(
    title: "Radial Wave: 10 Filled Bands",
    subtitle: "z = sin(2.5 r) · exp(-r / 3) over a 50-by-50 grid",
    fill: "level",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
