// geom-dotplot: stacked dots over a binned x-distribution.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = range(0, 80).map(i => (
  x: calc.sin(i * 0.27) * 3 + i * 0.06,
))

#plot(
  data: d,
  mapping: aes(x: "x"),
  layers: (geom-dotplot(bins: 14),),
  labels: labels(title: "geom-dotplot(bins: 14)"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#plot(
  data: d,
  mapping: aes(x: "x"),
  layers: (geom-dotplot(binwidth: 0.4, dotsize: 0.9),),
  labels: labels(title: "geom-dotplot(binwidth: 0.4, dotsize: 0.9)"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#plot(
  data: d,
  mapping: aes(x: "x"),
  layers: (geom-dotplot(bins: 14, stackratio: 1.4),),
  labels: labels(
    title: "geom-dotplot(stackratio: 1.4) Leaves a Gap Between Dots",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
