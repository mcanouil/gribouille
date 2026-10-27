// Smoke render: geom-boxplot and geom-crossbar under coord-radial(theta: "y").
//
// Each category of x takes its own ring, and the y values sweep the angle,
// as the points drawn on top do. The box spans the quartiles along the arc,
// the median is a spoke across the ring, and the whiskers are arcs.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let raw = (
  ("A", "B", "C")
    .enumerate()
    .map(((k, q)) => range(11).map(i => (q: q, y: i * (k + 1) + 2 * k)))
    .flatten()
    + ((q: "A", y: 40),)
)

#let summary = (
  (q: "A", y: 3, lo: 1, hi: 6),
  (q: "B", y: 8, lo: 5, hi: 10),
  (q: "C", y: 4, lo: 2, hi: 9),
)

#let cell(data, mapping, layers) = plot(
  data: data,
  mapping: mapping,
  layers: layers,
  coord: coord-radial(theta: "y"),
  width: 5cm,
  height: 5cm,
)

#grid(
  columns: 2,
  column-gutter: 0.4cm,
  cell(raw, aes(x: "q", y: "y"), (geom-boxplot(), geom-point(size: 1pt, colour: red))),
  cell(summary, aes(x: "q", y: "y", ymin: "lo", ymax: "hi"), (geom-crossbar(), geom-point(size: 2pt, colour: red))),
)
