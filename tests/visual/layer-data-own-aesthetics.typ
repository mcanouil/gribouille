// A layer with its own data that maps only its own aesthetics does not train
// the inherited plot x and y. The rect keeps the numeric axes and is drawn
// behind the points.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let points = range(1, 8).map(i => (a: i, b: i * 2))
#let band = ((lo: 2, hi: 5, floor: 4, ceiling: 9),)
#plot(
  data: points,
  mapping: aes(x: "a", y: "b"),
  layers: (
    geom-rect(
      data: band,
      mapping: aes(xmin: "lo", xmax: "hi", ymin: "floor", ymax: "ceiling"),
      fill: luma(85%),
    ),
    geom-point(),
  ),
  width: 8cm,
  height: 6cm,
)
