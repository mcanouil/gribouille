// A figure tag drawn above the title, styled by the plot-tag theme element.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (geom-point(size: 2.5pt, alpha: 0.75),),
  labels: labels(
    tag: "A",
    title: "Engine Displacement Versus Highway Fuel Economy",
    subtitle: "One panel of a larger figure",
    x: "Displacement (L)",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
