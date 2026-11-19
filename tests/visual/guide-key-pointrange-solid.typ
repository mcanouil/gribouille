// A pointrange key is a solid dot, as its point is.
//
// The point of each pointrange is filled with the group colour and has no
// outline. Each legend key is a solid dot in the same colour.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: (
    (cat: "A", mid: 2, lo: 1, hi: 3),
    (cat: "B", mid: 3, lo: 2, hi: 4),
    (cat: "C", mid: 1.5, lo: 0.5, hi: 2.5),
  ),
  mapping: aes(x: "cat", y: "mid", ymin: "lo", ymax: "hi", colour: "cat"),
  layers: (geom-pointrange(),),
  width: 8cm,
  height: 5cm,
)
