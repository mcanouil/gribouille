// geom-quantile: quantile-regression lines at user-supplied tau values.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = ()
#for i in range(0, 60) {
  let x = i * 0.2
  let y = 0.6 * x + calc.sin(i * 0.4) * 1.5 + (calc.rem(i, 7) - 3) * 0.4
  d.push((x: x, y: y))
}

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 2pt, alpha: 0.4),
    geom-quantile(),
  ),
  labels: labels(title: "Default Quantiles (0.25, 0.5, 0.75)"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 2pt, alpha: 0.4),
    geom-quantile(quantiles: (0.1, 0.5, 0.9), stroke: 1pt),
  ),
  labels: labels(title: "Decile Bands: Quantiles (0.1, 0.5, 0.9)"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
