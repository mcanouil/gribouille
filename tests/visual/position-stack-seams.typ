// Smoke render: stacked segments share their side edges.
//
// Left: a stacked histogram where each group is empty in some bins. The
// segments of one bin start and end at the same x, whatever the draw order of
// the groups, and an empty group paints no stripe on top of the stack.
// Right: stacked columns on a discrete x where one group is zero in a column.
// The zero segment draws nothing, and each column keeps its own width. The
// top segment of Q3 is thinner than the seal overlap, and the segment below
// it still stops at its lower edge. Q4 holds a negative value, so its
// segments overlap, and each one keeps its full height.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let bins = (
  (g: "c", x: 1.5),
  (g: "c", x: 2.5),
  (g: "c", x: 2.6),
  (g: "c", x: 3.5),
  (g: "a", x: 0.5),
  (g: "a", x: 1.5),
  (g: "a", x: 1.6),
  (g: "a", x: 1.7),
  (g: "a", x: 2.5),
  (g: "b", x: 2.5),
  (g: "b", x: 3.5),
  (g: "b", x: 3.6),
  (g: "b", x: 4.5),
)

#let cols = (
  (q: "Q1", g: "a", y: 3),
  (q: "Q1", g: "b", y: 0),
  (q: "Q1", g: "c", y: 2),
  (q: "Q2", g: "a", y: 0),
  (q: "Q2", g: "b", y: 4),
  (q: "Q2", g: "c", y: 1),
  (q: "Q3", g: "a", y: 0.02),
  (q: "Q3", g: "c", y: 4.98),
  (q: "Q4", g: "a", y: 2),
  (q: "Q4", g: "b", y: -1),
  (q: "Q4", g: "c", y: 3),
)

#stack(
  dir: ltr,
  spacing: 0.5cm,
  plot(
    data: bins,
    mapping: aes(x: "x", fill: "g"),
    layers: (geom-histogram(binwidth: 1),),
    labels: labels(title: "histogram, stacked"),
    width: 7cm,
    height: 5cm,
  ),
  plot(
    data: cols,
    mapping: aes(x: "q", y: "y", fill: "g"),
    layers: (geom-col(position: "stack"),),
    labels: labels(title: "stacked columns"),
    width: 7cm,
    height: 5cm,
  ),
)
