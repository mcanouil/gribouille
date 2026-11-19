// A size ladder for a layer whose fill is mapped to another guide.
//
// The fill and shape legend lists the two species. The size ladder below it
// has four solid ink circles that grow with the weight, not four empty ones.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: (
    (x: 1, y: 2, sp: "a", w: 1),
    (x: 2, y: 4, sp: "b", w: 2),
    (x: 3, y: 3, sp: "a", w: 3),
    (x: 4, y: 5, sp: "b", w: 4),
  ),
  mapping: aes(x: "x", y: "y", fill: "sp", shape: "sp", size: "w"),
  layers: (geom-point(),),
  width: 10cm,
  height: 6cm,
)
