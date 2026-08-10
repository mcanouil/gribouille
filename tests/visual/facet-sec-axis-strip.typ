// Secondary axes under facets, against the strip bands.
//
// A panel draws its secondary x axis at its top edge, which is where the
// strip band above it is painted, and its secondary y at the right edge,
// where facet-grid paints the row strip. The cell reserves the axis depth
// between the two, so:
//   1. facet-wrap: the top row's secondary ticks and labels sit under the
//      strip text rather than running into it.
//   2. facet-grid: the top row's secondary x survives the column strips,
//      which are painted after every panel, and the right column's
//      secondary y survives the row strips.
// The secondary titles stay outside both, at the edge of the panel grid.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let data = (
  (x: 1, y: 1, g: "A", h: "one"),
  (x: 2, y: 2, g: "A", h: "two"),
  (x: 3, y: 3, g: "B", h: "one"),
  (x: 4, y: 4, g: "B", h: "two"),
)

#stack(
  dir: ttb,
  spacing: 0.6cm,
  plot(
    data: data,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    facet: facet-wrap("g", ncolumn: 2),
    scales: scales(x: scale-continuous(secondary: sec-axis(name: "Sec x"))),
    width: 12cm,
    height: 5cm,
  ),
  plot(
    data: data,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    facet: facet-grid(rows: "h", columns: "g"),
    scales: scales(
      x: scale-continuous(secondary: sec-axis(name: "Sec x")),
      y: scale-continuous(secondary: sec-axis(name: "Sec y")),
    ),
    width: 12cm,
    height: 7cm,
  ),
)
