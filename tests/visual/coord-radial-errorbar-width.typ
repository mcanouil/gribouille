// A numeric `width` or `height` sizes the caps of errorbar and errorbarh
// under coord-radial, as it does on a Cartesian panel.
//
// Row one: discrete x on theta. Each spine is a spoke, and each cap is an arc
// across `width` of the category slot, so the caps of width 0.8 nearly touch
// and the caps of width 0.2 stay narrow.
//
// Row two: continuous centre on the radius. Each spine is an arc, and each cap
// is a radial tick across `width` (or `height`) data units. A cap that reaches
// the centre stops there. The last cell keeps a Typst length cap.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let groups = (
  ("a", "b", "c", "d")
    .enumerate()
    .map(((i, g)) => (
      g: g,
      lo: i + 1,
      hi: i + 3,
    ))
)

#let bars = range(1, 5).map(i => (
  x: i,
  y: i,
  lo: i * 0.5,
  hi: i * 2.5,
))

#let cell(data, mapping, layer, theta) = plot(
  data: data,
  mapping: mapping,
  layers: (layer,),
  coord: coord-radial(theta: theta),
  width: 4cm,
  height: 4cm,
)

#let discrete = aes(x: "g", ymin: "lo", ymax: "hi")
#let discrete-h = aes(y: "g", xmin: "lo", xmax: "hi")
#let vertical = aes(x: "x", ymin: "lo", ymax: "hi")
#let horizontal = aes(y: "y", xmin: "lo", xmax: "hi")

#grid(
  columns: 4,
  column-gutter: 0.4cm,
  row-gutter: 0.4cm,
  cell(groups, discrete, geom-errorbar(width: 0.8), "x"),
  cell(groups, discrete, geom-errorbar(width: 0.2), "x"),
  cell(groups, discrete-h, geom-errorbarh(height: 0.8), "y"),
  cell(groups, discrete-h, geom-errorbarh(height: 0.2), "y"),
  cell(bars, vertical, geom-errorbar(width: 0.8), "y"),
  cell(bars, vertical, geom-errorbar(width: 1.5), "y"),
  cell(bars, horizontal, geom-errorbarh(height: 0.8), "x"),
  cell(bars, vertical, geom-errorbar(width: 0.3cm), "y"),
)
