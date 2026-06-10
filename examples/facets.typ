// facet-wrap: one panel per level of a discrete variable.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", colour: "class"),
  layers: (geom-point(size: 2.5pt, alpha: 0.85),),
  facet: facet-wrap("cyl", ncolumn: 3),
  guides: guides(colour: none),
  labs: labs(
    title: "Highway Fuel Economy by Cylinder Count",
    x: "Displacement (L)",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
