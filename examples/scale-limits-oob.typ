// Out-of-range handling when a scale `limits` is set.
//
// Default `oob: "drop"` removes rows whose mapped value falls outside the
// limits; `oob: "squish"` clamps them to the nearest endpoint instead.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let base(extra-scales) = plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", fill: "cty"),
  layers: (geom-point(size: 4pt, alpha: 0.85),),
  scales: extra-scales,
  labels: labels(
    x: "Displacement (L)",
    y: "Highway mpg",
    fill: "City mpg",
  ),
  theme: theme-minimal(),
  width: 10cm,
  height: 7cm,
)

#grid(
  columns: 1,
  row-gutter: 0.6cm,
  base(scales(fill: scale-viridis-c(limits: (15, 25)))),
  base(scales(fill: scale-viridis-c(limits: (15, 25), oob: "squish"))),
)
