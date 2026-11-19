// With `missing-translate: false` the missing rows are dropped.
//
// The left plot shows the missing level. The right plot has no grey points and no (missing)
// key in its legend: the penguins with no recorded sex are not drawn.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let make(title, ..args) = plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", colour: "sex"),
  layers: (geom-point(size: 2pt),),
  scales: scales(colour: scale-discrete(..args)),
  labels: labels(title: title),
  width: 7.5cm,
  height: 6cm,
)

#stack(
  dir: ltr,
  spacing: 0.5cm,
  make("default"),
  make("missing-translate: false", missing-translate: false),
)
