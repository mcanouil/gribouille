// Explicit y limits pin the axis of a ribbon.
//
// The band reaches from -5 to 20. The left plot has no limits, so the y axis
// widens to cover the band. The right plot sets `limits: (0, 10)`: the axis
// stays at 0 to 10, and the band is cut at the panel edge instead of
// stretching the axis.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 4, lo: -5, hi: 20),
  (x: 2, y: 5, lo: 1, hi: 8),
  (x: 3, y: 6, lo: 2, hi: 12),
)

#let chart(limits) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", ymin: "lo", ymax: "hi"),
  layers: (geom-ribbon(alpha: 0.4), geom-line()),
  scales: if limits == none { scales() } else {
    scales(y: scale-continuous(limits: limits))
  },
  width: 6cm,
  height: 4.5cm,
)

#grid(columns: 2, gutter: 0.5cm, chart(none), chart((0, 10)))
