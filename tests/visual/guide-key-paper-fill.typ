// A legend key for a mapped shape draws like the mark.
//
// The markers have a paper fill and an ink outline, and so do the legend
// keys. None of the keys is solid ink.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", shape: "island"),
  layers: (geom-point(size: 3pt),),
  width: 10cm,
  height: 7cm,
)
