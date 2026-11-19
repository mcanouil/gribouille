// A missing value on a discrete x axis gets its own slot at the end.
//
// Both plots have the ticks a, b and NA, with NA last. The left plot draws
// points and the right one draws boxplots, and the rows with a missing x sit in
// the NA slot of each.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let data = (
  (g: "a", y: 1),
  (g: "a", y: 2),
  (g: "a", y: 3),
  (g: "a", y: 4),
  (g: "b", y: 3),
  (g: "b", y: 4),
  (g: "b", y: 5),
  (g: "b", y: 6),
  (g: none, y: 5),
  (g: none, y: 6),
  (g: none, y: 7),
  (g: none, y: 8),
)

#let make(geom, title) = plot(
  data: data,
  mapping: aes(x: "g", y: "y"),
  layers: (geom,),
  labels: labels(title: title),
  width: 7cm,
  height: 6cm,
)

#stack(
  dir: ltr,
  spacing: 0.5cm,
  make(geom-point(size: 2pt), "geom-point"),
  make(geom-boxplot(), "geom-boxplot"),
)
