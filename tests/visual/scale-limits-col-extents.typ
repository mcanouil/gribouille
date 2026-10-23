// Explicit x limits on geom-col choose the bars, and the kept bars draw whole.
//
// Bars at x = 1 to 6. The left plots have no limits, so the scale widens by
// half a bar and every bar sits inside the panel. The right plots set
// `limits: (2, 5)`: the bars at 1 and 6, centred outside the limits, are
// dropped, and the bars at 2 to 5 are drawn at full width, with the axis
// widened to fit them and the normal expansion on top. The bottom row dodges
// two groups per x, and each kept group draws whole.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(1, 7).map(i => (x: i, y: calc.rem(i * 3, 5) + 1))
#let dodged = (
  range(1, 7)
    .map(i => (
      (x: i, y: calc.rem(i * 3, 5) + 1, g: "a"),
      (x: i, y: calc.rem(i * 2, 5) + 1, g: "b"),
    ))
    .join()
)

#let chart(data, mapping, layer, limits) = plot(
  data: data,
  mapping: mapping,
  layers: (layer,),
  scales: if limits == none { scales() } else {
    scales(x: scale-continuous(limits: limits))
  },
  guides: guides(fill: none),
  width: 6cm,
  height: 5cm,
)

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  ..(none, (2, 5)).map(limits => chart(
    d,
    aes(x: "x", y: "y"),
    geom-col(),
    limits,
  )),
  ..(none, (2, 5)).map(limits => chart(
    dodged,
    aes(x: "x", y: "y", fill: "g"),
    geom-col(position: "dodge"),
    limits,
  )),
)
