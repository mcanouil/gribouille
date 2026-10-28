// Smoke render: a zero group in a stacked bar under coord-radial.
//
// Group b is zero in category B, so its wedge has no thickness there and draws
// nothing. No arc of its colour shows on the boundary between a and c.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (q: "A", g: "a", y: 2),
  (q: "A", g: "b", y: 1),
  (q: "A", g: "c", y: 2),
  (q: "B", g: "a", y: 2),
  (q: "B", g: "b", y: 0),
  (q: "B", g: "c", y: 3),
  (q: "C", g: "a", y: 1),
  (q: "C", g: "b", y: 2),
  (q: "C", g: "c", y: 1),
)

#plot(
  data: d,
  mapping: aes(x: "q", y: "y", fill: "g"),
  layers: (geom-col(position: "stack", width: 1),),
  coord: coord-radial(),
  width: 7cm,
  height: 7cm,
)
