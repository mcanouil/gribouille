// End-to-end check that scale `labels:` accepts a callback function and
// composes with the format helpers.

#import "../../lib.typ": (
  aes, format-comma, format-number, format-percent, format-scientific,
  format-title, geom-col, geom-point, labels, plot, scale-x-continuous,
  scale-x-discrete, scale-y-continuous, typst,
)

#let d = (
  (x: 1234, y: 0.001),
  (x: 23456, y: 0.0001),
  (x: 345678, y: 0.000001),
  (x: 4567890, y: 0.00000001),
)

// format-number on x, format-scientific on y.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  scales: (
    scale-x-continuous(labels: format-comma()),
    scale-y-continuous(labels: format-scientific()),
  ),
  width: 10cm,
  height: 6cm,
)

// format-percent.
#let pct = (
  (x: "a", y: 0.1),
  (x: "b", y: 0.5),
  (x: "c", y: 0.9),
)
#plot(
  data: pct,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-col(),),
  scales: (scale-y-continuous(labels: format-percent()),),
  width: 10cm,
  height: 6cm,
)

// format-title with typst() composition: discrete fill swatches show
// title-cased labels (string returns) without markup eval.
#let groups = (
  (x: "alpha", y: 4),
  (x: "beta", y: 7),
  (x: "gamma", y: 3),
)
#plot(
  data: groups,
  mapping: aes(x: "x", y: "y", fill: "x"),
  layers: (geom-col(),),
  scales: (scale-x-discrete(labels: format-title()),),
  width: 10cm,
  height: 6cm,
)

// Custom inline closure on labels.
#plot(
  data: groups,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-col(),),
  scales: (scale-x-discrete(labels: x => "[" + x + "]"),),
  width: 10cm,
  height: 6cm,
)

// Combined: typst-tagged aes + labels callback returning markup.
#plot(
  data: groups,
  mapping: aes(x: "x", y: "y", fill: typst("x")),
  layers: (geom-col(),),
  scales: (scale-x-discrete(labels: x => "$" + x + "$"),),
  width: 10cm,
  height: 6cm,
)

labels callback smoke test passed.
