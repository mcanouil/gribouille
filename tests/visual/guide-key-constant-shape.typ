// A legend key draws with the shape the layer pins.
//
// The points are triangles, coloured by group, and the two legend keys are
// triangles in the same colours.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: (
    (x: 1, y: 1, g: "a"),
    (x: 2, y: 2, g: "b"),
  ),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt, shape: "triangle"),),
  width: 8cm,
  height: 5cm,
)
