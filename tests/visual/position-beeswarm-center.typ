// `position-beeswarm(method: "center")` stacks points by count.
//
// Two discrete rows on one panel: "many" holds 30 points and "few" holds 8.
// The row with 30 points is wider than the row with 8. In each row, the points
// of a value bin form a centred stack, and the step between neighbours is the
// same in both rows. Points at a bin sit on the bin centre, so they line up in
// horizontal layers.

#import "../../lib.typ": *

#let data = (
  range(30).map(i => (g: "many", v: calc.rem(i * 7, 11)))
    + range(8).map(i => (g: "few", v: calc.rem(i * 5, 11)))
)

#plot(
  data: data,
  mapping: aes(x: "g", y: "v"),
  layers: (
    geom-point(
      size: 3pt,
      position: position-beeswarm(method: "center", binwidth: 1, spacing: 0.06),
    ),
  ),
  width: 8cm,
  height: 7cm,
)
