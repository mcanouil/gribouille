// Binned layers pad x to the bin edges, and a data column named `width` does
// not pad x.
//
// Top row: a histogram and a frequency polygon over the same five bins from
// 0 to 6. The histogram x axis covers the bins, 0 to 6, plus the normal
// expansion: the outer bars sit at the panel edges with no empty bin beside
// them. The frequency polygon gets the same axis.
//
// Bottom row: bars at x = 1 to 4 from data that has a `width` column. On the
// left the column is plain data, so the axis pads half a bar, as it does with
// no column. On the right two groups dodge with widths 0.3 and 0.7, which
// fill the whole gap, and the outer bars stay inside the panel.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let binned = range(20).map(i => (v: calc.rem(i * 7, 13) * 0.5))
#let bars = range(1, 5).map(i => (x: i, y: calc.rem(i * 3, 5) + 1, width: 1))
#let mixed = (
  range(1, 5)
    .map(i => (
      (x: i, y: calc.rem(i * 3, 5) + 1, g: "a", width: 0.3),
      (x: i, y: calc.rem(i * 2, 5) + 1, g: "b", width: 0.7),
    ))
    .join()
)

#let chart(data, mapping, layer) = plot(
  data: data,
  mapping: mapping,
  layers: (layer,),
  guides: guides(fill: none),
  width: 6cm,
  height: 5cm,
)

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  chart(binned, aes(x: "v"), geom-histogram(bins: 5)),
  chart(binned, aes(x: "v"), geom-freqpoly(bins: 5)),

  chart(bars, aes(x: "x", y: "y"), geom-col()),
  chart(mixed, aes(x: "x", y: "y", fill: "g"), geom-col(position: "dodge")),
)
