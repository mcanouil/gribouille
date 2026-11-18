// Smoke render: annotate() aesthetics are constants, never scaled.
//
// Points map a discrete colour to two levels. The annotated segment, text and
// point carry colour: red or colour: black. Each is drawn in that colour,
// does not panic the colour scale, and adds no legend key. The legend lists
// only the levels "a" and "b".

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(1, 8).map(i => (
  x: i,
  y: i * 2,
  g: if calc.odd(i) { "a" } else { "b" },
))
#plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (
    geom-point(),
    annotate("segment", x: 1, xend: 5, y: 3, yend: 3, colour: red),
    annotate("text", x: 6, y: 4, label: "red", colour: red),
    annotate("point", x: 3, y: 10, colour: black, fill: black, size: 4pt),
    annotate("text", x: 3, y: 12, label: "black", colour: black),
  ),
  width: 8cm,
  height: 6cm,
)
