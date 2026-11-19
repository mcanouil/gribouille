// A missing value on a manual size scale with no `missing-value` draws at the geom
// default size, and its legend key does too.
//
// The two named levels take the sizes of the scale. The missing mark and the missing
// key have the same size, the point default.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: (
    (x: 1, y: 1, g: "a"),
    (x: 2, y: 2, g: "b"),
    (x: 3, y: 3, g: none),
  ),
  mapping: aes(x: "x", y: "y", size: "g"),
  scales: scales(size: scale-manual(values: (3pt, 6pt))),
  layers: (geom-point(),),
  width: 8cm,
  height: 5cm,
)
