// A missing value on a discrete shape scale is its own level.
//
// The penguins that have no recorded sex draw as a circle with a cross,
// and the legend lists female, male and NA, with NA on a circle with a cross.
// The other two shapes keep their usual marks.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", shape: "sex"),
  layers: (geom-point(size: 2pt),),
  labels: labels(x: "Flipper length", y: "Body mass"),
  width: 10cm,
  height: 7cm,
)
