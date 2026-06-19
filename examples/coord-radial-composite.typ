// Composite geoms under coord-radial: errorbar / pointrange / linerange /
// crossbar / boxplot all render polar wedges, radial spines and arc caps
// instead of cartesian rectangles.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let summaries = (
  (cat: "A", lo: 1, mid: 2, hi: 3),
  (cat: "B", lo: 2, mid: 3.2, hi: 4.4),
  (cat: "C", lo: 1.5, mid: 2.8, hi: 4),
  (cat: "D", lo: 0.8, mid: 1.6, hi: 2.4),
  (cat: "E", lo: 2.4, mid: 3.6, hi: 4.8),
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: summaries,
    mapping: aes(x: "cat", y: "mid", ymin: "lo", ymax: "hi", colour: "cat"),
    layers: (
      geom-errorbar(width: 0.5),
      geom-pointrange(size: 4pt),
    ),
    coord: coord-radial(),
    labels: labels(title: "Errorbar + Pointrange Under Coord-Radial"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: summaries,
    mapping: aes(x: "cat", y: "mid", ymin: "lo", ymax: "hi", fill: "cat"),
    layers: (geom-crossbar(width: 0.6),),
    coord: coord-radial(),
    labels: labels(title: "Crossbar Wedges Under Coord-Radial"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
