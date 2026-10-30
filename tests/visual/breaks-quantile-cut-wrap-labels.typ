// Tied quantile ticks, rounded cut labels, and wrapped accented strips.
//
// Left: `breaks-quantile` on tied data draws one tick per distinct value, where
// it used to overdraw the same tick. Middle: `cut-interval` bin labels print
// three digits, where they used to print the full float. Right: `label-wrap`
// wraps accented strip text by character, where it used to count bytes.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let tied = ((x: 3, y: 1), (x: 3, y: 2), (x: 3, y: 3), (x: 7, y: 4))

#let binned = {
  let values = (0, 0.2, 0.5, 0.7, 1)
  let bins = cut-interval(values, n: 3)
  values.zip(bins).map(((v, b)) => (x: b, y: v))
}

#let accents = (
  (g: "été chaud", x: 1, y: 1),
  (g: "été chaud", x: 2, y: 2),
  (g: "hiver doux", x: 1, y: 3),
  (g: "hiver doux", x: 2, y: 4),
)

#grid(
  columns: 3,
  gutter: 0.5cm,
  plot(
    data: tied,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    scales: scales(x: scale-continuous(breaks: breaks-quantile())),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: binned,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: accents,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    facet: facet-wrap("g", labeller: label-wrap(width: 5)),
    width: 6cm,
    height: 4cm,
  ),
)
