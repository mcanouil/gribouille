// Smoke render: scale limits follow the user's aesthetic under coord-flip.
//
// With limits on the user's y, geom-col draws horizontal bars, geom-point
// draws its dots and stat-summary draws its points, all on a value axis from
// 0 to 8 along the bottom. The last panel limits the user's x to 0 to 3, so
// only the three rows with n up to 3 draw.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = ((k: "a", v: 3), (k: "b", v: 5), (k: "c", v: 2), (k: "c", v: 4))
#let ys = scales(y: scale-continuous(limits: (0, 8)))

#grid(
  columns: 2,
  gutter: 0.5cm,
  plot(
    data: d,
    mapping: aes(x: "k", y: "v"),
    layers: (geom-col(),),
    scales: ys,
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: d,
    mapping: aes(x: "k", y: "v"),
    layers: (geom-point(),),
    scales: ys,
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),

  plot(
    data: d,
    mapping: aes(x: "k", y: "v"),
    layers: (geom-pointrange(stat: stat-summary(fun: "median")),),
    scales: ys,
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),
  plot(
    data: (..d, (k: "z", v: 9)).enumerate().map(((i, r)) => (..r, n: i + 1)),
    mapping: aes(x: "n", y: "v"),
    layers: (geom-point(),),
    scales: scales(x: scale-continuous(limits: (0, 3))),
    coord: coord-flip(),
    width: 6cm,
    height: 4cm,
  ),
)
