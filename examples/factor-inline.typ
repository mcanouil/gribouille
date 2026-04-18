// Inline aesthetic coercion: force a numeric column to be treated as discrete
// for the colour aesthetic without changing the underlying data.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let obs = ()
#for i in range(0, 12) {
  obs.push((x: i, y: calc.sin(i / 2.0) * 5 + 5, cluster: calc.rem(i, 3)))
}

#plot(
  data: obs,
  mapping: aes(x: "x", y: "y", colour: as-factor("cluster")),
  layers: (geom-point(size: 4pt),),
  labs: labs(title: "cluster forced to factor on colour"),
  width: 10cm,
  height: 7cm,
)
