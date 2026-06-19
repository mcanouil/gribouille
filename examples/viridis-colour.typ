// Viridis continuous fill scale.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", fill: "cty"),
  layers: (geom-point(size: 4pt, alpha: 0.9),),
  scales: (scale-fill-viridis-c(),),
  labels: labels(
    title: "Viridis Continuous Fill",
    subtitle: "Colour encodes city mpg across the displacement / highway plane",
    x: "Displacement (L)",
    y: "Highway mpg",
    fill: "City mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
