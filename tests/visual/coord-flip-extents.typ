// Segments, curves, rectangles, and 2D bins follow coord-flip.
//
// Under coord-flip each mark draws on the swapped axes: a segment and a curve
// run from (x, y) to (xend, yend) with both ends swapped, a rectangle spans
// its x range vertically and its y range horizontally, and the 2D bins tile
// the same cells as the unflipped plot, transposed.

#import "../../lib.typ": *

#let seg = (
  (x: 1, y: 1, xend: 4, yend: 2),
  (x: 2, y: 3, xend: 3, yend: 6),
)
#let rects = (
  (xmin: 1, xmax: 2, ymin: 1, ymax: 5),
  (xmin: 3, xmax: 6, ymin: 2, ymax: 3),
)
#let pts = range(60).map(i => (
  x: calc.rem(i * 7, 13) / 2,
  y: calc.rem(i * 5, 11) / 2,
))

#let pair(data, mapping, layer) = (
  plot(
    data: data,
    mapping: mapping,
    layers: (layer,),
    width: 5cm,
    height: 4cm,
  ),
  plot(
    data: data,
    mapping: mapping,
    layers: (layer,),
    coord: coord-flip(),
    width: 5cm,
    height: 4cm,
  ),
)

#let ends = aes(x: "x", y: "y", xend: "xend", yend: "yend")
#let extents = aes(xmin: "xmin", xmax: "xmax", ymin: "ymin", ymax: "ymax")

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  ..pair(seg, ends, geom-segment()),
  ..pair(seg, ends, geom-curve()),
  ..pair(rects, extents, geom-rect()),
  ..pair(pts, aes(x: "x", y: "y"), geom-bin-2d(bins: 4)),
)
