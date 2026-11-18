// A missing value on a discrete colour scale draws in grey.
//
// Points whose sex is missing are grey, and the legend lists female, male and
// NA, with a grey key for NA. Female and male keep their palette colours.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", colour: "sex"),
  layers: (geom-point(size: 2pt),),
  labels: labels(x: "Flipper length", y: "Body mass"),
  width: 10cm,
  height: 7cm,
)
