// A cell that a continuous scale cannot read drops its row.
//
// The data holds six points on a line. Point 2 has the colour `"zz"`, point 4
// has a NaN colour, and point 6 has the y value `"zz"` under y `limits`. Each of
// these rows drops, so three points draw, in viridis colours. Before the fix,
// point 2 raised `invalid float` and point 4 raised `cannot compare float.nan`.
// The limits check kept point 6 as in range, and only the geom skipped it.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: (
    (x: 1, y: 1, c: 1),
    (x: 2, y: 2, c: "zz"),
    (x: 3, y: 3, c: 3),
    (x: 4, y: 4, c: float.nan),
    (x: 5, y: 5, c: 5),
    (x: 6, y: "zz", c: 6),
  ),
  mapping: aes(x: "x", y: "y", colour: "c"),
  layers: (geom-point(size: 4pt),),
  scales: scales(
    x: scale-continuous(limits: (0, 7)),
    y: scale-continuous(limits: (0, 7)),
    colour: scale-viridis-c(),
  ),
  width: 8cm,
  height: 5cm,
)
