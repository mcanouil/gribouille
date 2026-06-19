// `after-scale` on the `shape` channel transforms the resolved shape
// kind. Here a per-row predicate flips between two shapes regardless of
// the trained shape scale.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, flag: true),
  (x: 2, y: 2, flag: false),
  (x: 3, y: 3, flag: true),
  (x: 4, y: 2, flag: false),
  (x: 5, y: 3, flag: true),
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    shape: after-scale((_, ctx) => if ctx.row.flag { "circle" } else {
      "square"
    }),
  ),
  layers: (geom-point(size: 4pt),),
  labels: labels(title: "Per-Row Shape via After-Scale"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
