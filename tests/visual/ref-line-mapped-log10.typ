// Smoke render: mapped reference lines on log10 axes.
//
// Left panel: on a log10 y axis, a mapped hline at 1 and another at 3 draw at
// y = 1 and y = 3, and a scalar hline at 10 draws at y = 10. Right panel: a
// mapped vline at 3 on a log10 x axis draws at x = 3. A mapped value is read
// in the space the scale was trained in, so log10 is applied once.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(1, 13).map(i => (x: i, y: i))

#grid(
  columns: 2,
  gutter: 8pt,
  plot(
    data: d,
    width: 8cm,
    height: 6cm,
    mapping: aes(x: "x", y: "y"),
    layers: (
      geom-point(),
      geom-hline(data: ((t: 1), (t: 3)), mapping: aes(yintercept: "t")),
      geom-hline(yintercept: 10, colour: red),
    ),
    scales: scales(y: scale-log10()),
  ),
  plot(
    data: d,
    width: 8cm,
    height: 6cm,
    mapping: aes(x: "x", y: "y"),
    layers: (
      geom-point(),
      geom-vline(data: ((t: 3),), mapping: aes(xintercept: "t")),
    ),
    scales: scales(x: scale-log10()),
  ),
)
