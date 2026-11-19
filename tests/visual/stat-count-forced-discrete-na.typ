// A numeric column forced discrete keeps its missing cells as the missing level
// through `stat-count`.
//
// The x axis has ticks 1, 2 and (missing), and the bar above it counts the two
// missing cells. Before, the missing level had no bar.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: (
    (x: 1),
    (x: 1),
    (x: 2),
    (x: none),
    (x: none),
  ),
  mapping: aes(x: as-factor("x")),
  layers: (geom-bar(),),
  width: 8cm,
  height: 5cm,
)
