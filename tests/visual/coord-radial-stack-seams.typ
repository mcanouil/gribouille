// Smoke render: stacked wedges share their edges under coord-radial.
//
// First: theta on x. The wedges of one category start and end at the same
// angle, and each stack keeps its outer arc on the data. Second: theta on y.
// The wedges of one ring start and end at the same radius. Third: theta on y
// with position fill. Each ring spans the full circle, so its last group
// meets its first one at 12 o'clock with no light seam between them. Fourth:
// a pie whose stack holds a negative value, so group b spans the wedges of
// c and d. Group b shows from 2.5 to 3, and c and d keep their own spans.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  ("A", "B", "C", "D", "E")
    .enumerate()
    .map(((i, q)) => ("a", "b", "c")
      .enumerate()
      .map(((j, g)) => (q: q, g: g, y: 1 + calc.rem(i * 3 + j * 2, 4))))
    .flatten()
)

#let nested = (
  (q: "A", g: "a", y: 3),
  (q: "A", g: "b", y: -2),
  (q: "A", g: "c", y: 0.5),
  (q: "A", g: "d", y: 1),
)

#let cell(position, theta, title, data: d) = plot(
  data: data,
  mapping: aes(x: "q", y: "y", fill: "g"),
  layers: (geom-col(position: position, width: 1),),
  coord: coord-radial(theta: theta),
  labels: labels(title: title),
  width: 5.5cm,
  height: 5.5cm,
)

#stack(
  dir: ltr,
  spacing: 0.4cm,
  cell("stack", "x", "stack, theta x"),
  cell("stack", "y", "stack, theta y"),
  cell("fill", "y", "fill, theta y"),
  cell("stack", "y", "negative, theta y", data: nested),
)
