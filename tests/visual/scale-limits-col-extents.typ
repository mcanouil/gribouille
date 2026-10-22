// Smoke render: explicit x limits on geom-col are kept as given.
//
// Bars at x = 1 to 6. The left plot has no limits, so the scale widens by
// half a bar and every bar sits inside the panel. The right plot sets
// `limits: (2, 5)`, which the scale keeps: the axis runs from 2 to 5, the
// bars at 1 and 6, outside the limits, are dropped, and the bars at 2 and 5
// are cut at the panel border.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(1, 7).map(i => (x: i, y: calc.rem(i * 3, 5) + 1))

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..(none, (2, 5)).map(limits => plot(
    data: d,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-col(),),
    scales: if limits == none { scales() } else {
      scales(x: scale-continuous(limits: limits))
    },
    width: 6cm,
    height: 5cm,
  )),
)
