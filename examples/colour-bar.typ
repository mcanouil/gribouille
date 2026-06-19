// A colourbar guide appears automatically when fill is trained continuously.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", fill: "cty"),
  layers: (geom-point(size: 4pt, alpha: 0.85),),
  labels: labels(
    title: "Highway Versus Engine Displacement, Coloured by City mpg",
    x: "Displacement (L)",
    y: "Highway mpg",
    fill: "City mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
