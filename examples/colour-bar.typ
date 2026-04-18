// Continuous colour guide: a colourbar appears automatically when the
// colour aesthetic is trained continuously.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = ()
#for i in range(0, 40) {
  df.push((x: i, y: calc.cos(i / 4.0) * 6, temp: i * 1.5))
}

#plot(
  data: df,
  mapping: aes(x: "x", y: "y", colour: "temp"),
  layers: (geom-point(size: 5pt),),
  labs: labs(title: "Colourbar guide", colour: "Temperature"),
  width: 11cm,
  height: 7cm,
)
