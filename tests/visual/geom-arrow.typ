// Visual: arrowheads on the line geoms. Checks that heads sit on the line,
// point along it, follow a per-row mapped colour, stay solid under a dashed
// linetype, and stay tangent under coord-radial.

#import "../../lib.typ": (
  aes, arrow, coord-radial, geom-curve, geom-path, geom-segment, geom-spoke,
  plot, scale-continuous, scales,
)

#let hops = (
  (x: 0, y: 0, xend: 3, yend: 2, yr: 1),
  (x: 3, y: 2, xend: 3.2, yend: 2.1, yr: 2),
  (x: 3.2, y: 2.1, xend: 1, yend: 3, yr: 3),
  (x: 1, y: 3, xend: 4, yend: 0.5, yr: 4),
)

Curved hops with a per-row mapped colour: every head takes its own row colour,
including the 0.2-unit hop no ramp could carry on its own.

#plot(
  data: hops,
  mapping: aes(x: "x", y: "y", xend: "xend", yend: "yend", colour: "yr"),
  layers: (geom-curve(stroke: 1pt, arrow: arrow(length: 7pt)),),
  width: 10cm,
  height: 6cm,
)

Segments: `ends` at each of its three settings, and a closed head on the last.

#plot(
  data: (
    (x: 0, y: 3, xend: 4, yend: 3),
    (x: 0, y: 2, xend: 4, yend: 2),
  ),
  mapping: aes(x: "x", y: "y", xend: "xend", yend: "yend"),
  layers: (
    geom-segment(stroke: 1pt, arrow: arrow(length: 8pt, ends: "first")),
    geom-segment(
      data: ((x: 0, y: 1, xend: 4, yend: 1),),
      stroke: 1pt,
      arrow: arrow(length: 8pt, ends: "both"),
    ),
    geom-segment(
      data: ((x: 0, y: 0, xend: 4, yend: 0),),
      stroke: 1pt,
      arrow: arrow(length: 10pt, type: "closed"),
    ),
  ),
  width: 10cm,
  height: 6cm,
)

A dashed segment keeps a solid head.

#plot(
  data: ((x: 0, y: 0, xend: 4, yend: 2),),
  mapping: aes(x: "x", y: "y", xend: "xend", yend: "yend"),
  layers: (
    geom-segment(stroke: 1pt, linetype: "dashed", arrow: arrow(length: 10pt)),
  ),
  width: 10cm,
  height: 4cm,
)

Spokes: eight directed segments, heads pointing outward. The limits leave room
past the tips, since a head at the panel edge is clipped with the line it
belongs to.

#plot(
  data: range(0, 8).map(i => (x: 0, y: 0, angle: i * calc.pi / 4, r: 1)),
  mapping: aes(x: "x", y: "y", angle: "angle", radius: "r"),
  layers: (geom-spoke(stroke: 1pt, arrow: arrow(length: 7pt)),),
  scales: scales(
    x: scale-continuous(limits: (-1.5, 1.5)),
    y: scale-continuous(limits: (-1.5, 1.5)),
  ),
  width: 8cm,
  height: 8cm,
)

A path gets one head per group, at the end of the whole path.

#plot(
  data: (
    (x: 1, y: 1, k: "a"),
    (x: 3, y: 4, k: "a"),
    (x: 2, y: 2, k: "a"),
    (x: 4, y: 5, k: "a"),
    (x: 1, y: 5, k: "b"),
    (x: 2, y: 3, k: "b"),
    (x: 4, y: 1, k: "b"),
  ),
  mapping: aes(x: "x", y: "y", colour: "k"),
  layers: (geom-path(stroke: 1.2pt, arrow: arrow(length: 8pt)),),
  width: 10cm,
  height: 6cm,
)

Under `coord-radial` the head follows the last projected leg of the path, so it
points along the line as drawn rather than along the data-space direction.

#plot(
  data: (
    (x: 0, y: 1, k: "a"),
    (x: 90, y: 2, k: "a"),
    (x: 180, y: 3, k: "a"),
    (x: 270, y: 4, k: "a"),
  ),
  mapping: aes(x: "x", y: "y", colour: "k"),
  layers: (geom-path(stroke: 1.2pt, arrow: arrow(length: 8pt)),),
  scales: scales(x: scale-continuous(limits: (0, 360))),
  coord: coord-radial(),
  width: 8cm,
  height: 8cm,
)
