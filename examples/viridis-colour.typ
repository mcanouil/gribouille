// Viridis continuous colour scale.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = ()
#for i in range(0, 30) {
  df.push((x: i, y: calc.sin(i / 3.0) * 10, z: i * 3.0))
}

#plot(
  data: df,
  mapping: aes(x: "x", y: "y", colour: "z"),
  layers: (geom-point(size: 5pt),),
  scales: (scale-colour-viridis-c(),),
  labs: labs(title: "Viridis continuous"),
  width: 11cm,
  height: 7cm,
)
