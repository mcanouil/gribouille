// A rect layer with its own data inherits the plot mapping but draws from its
// own corners. The page must show the points with two shaded bands behind them;
// the bands' data has no `fl` or `bm` column, and that is not
// an error because `geom-rect` does not read `x` or `y`.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let pts = (
  (fl: 185, bm: 3200),
  (fl: 190, bm: 3600),
  (fl: 215, bm: 5000),
  (fl: 220, bm: 5400),
)
#let bands = (
  (a: 180, b: 195, c: 2500, d: 6500),
  (a: 210, b: 225, c: 2500, d: 6500),
)
#plot(
  data: pts,
  mapping: aes(x: "fl", y: "bm"),
  layers: (
    geom-rect(
      data: bands,
      mapping: aes(xmin: "a", xmax: "b", ymin: "c", ymax: "d"),
      alpha: 0.2,
    ),
    geom-point(),
  ),
  scales: scales(x: scale-continuous(), y: scale-continuous()),
  width: 8cm,
  height: 6cm,
)
