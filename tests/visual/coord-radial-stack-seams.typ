// Smoke render: stacked wedges share their edges under coord-radial.
//
// Left: theta on x. The wedges of one category start and end at the same
// angle, and each stack keeps its outer arc on the data. Middle: theta on y.
// The wedges of one ring start and end at the same radius. Right: theta on y
// with position fill. Each ring spans the full circle, so its last group
// meets its first one at 12 o'clock with no light seam between them. The
// rows run in a mixed group order, so the draw order of the groups does not
// set where an edge falls.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  ("A", "B", "C", "D", "E")
    .enumerate()
    .map(((i, q)) => ("c", "a", "b")
      .enumerate()
      .map(((j, g)) => (q: q, g: g, y: 1 + calc.rem(i * 3 + j * 2, 4))))
    .flatten()
)

#let cell(position, theta, title) = plot(
  data: d,
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
)
