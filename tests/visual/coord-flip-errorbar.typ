// Smoke render: errorbars follow coord-flip.
//
// Under coord-flip an errorbar draws as a horizontal bar on each level row,
// with its caps along the level axis, and an errorbarh draws as a vertical
// bar. Dodged errorbars keep their side-by-side offsets within each row.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (g: "a", k: "u", lo: 1, hi: 3),
  (g: "b", k: "u", lo: 4, hi: 8),
  (g: "c", k: "u", lo: 2, hi: 6),
  (g: "a", k: "w", lo: 2, hi: 5),
  (g: "b", k: "w", lo: 3, hi: 6),
  (g: "c", k: "w", lo: 1, hi: 4),
)

#grid(
  columns: 3,
  column-gutter: 0.5cm,
  plot(
    data: d.slice(0, 3),
    mapping: aes(x: "g", ymin: "lo", ymax: "hi"),
    layers: (geom-errorbar(),),
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: d.slice(0, 3),
    mapping: aes(y: "g", xmin: "lo", xmax: "hi"),
    layers: (geom-errorbarh(),),
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: d,
    mapping: aes(x: "g", ymin: "lo", ymax: "hi", colour: "k"),
    layers: (geom-errorbar(position: position-dodge(width: 0.6), width: 0.3),),
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),
)
