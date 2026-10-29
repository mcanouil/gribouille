// A weight cell that is not a number drops its row.
//
// Each bar counts its rows by weight. Class "a" has the weights 2 and "NA",
// class "b" has 3 and "x", and class "c" has 1. The two non-numeric weights
// drop their rows, so the bars are 2, 3, and 1 high. The points show the
// weighted mean of y per class: "a" keeps y = 4, "b" keeps y = 2, and "c"
// keeps y = 1. Before the fix, the weight "NA" raised `invalid float`.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (cls: "a", y: 4, w: 2),
  (cls: "a", y: 9, w: "NA"),
  (cls: "b", y: 2, w: 3),
  (cls: "b", y: 9, w: "x"),
  (cls: "c", y: 1, w: 1),
)

#plot(
  data: d,
  mapping: aes(x: "cls", weight: "w"),
  layers: (
    geom-bar(),
    geom-point(
      mapping: aes(y: "y"),
      stat: stat-summary(fun: "mean"),
      size: 4pt,
      colour: red,
    ),
  ),
  width: 8cm,
  height: 5cm,
)
