// Facet labellers: strip text driven by label-both() prefixes the variable name.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", colour: "class"),
  layers: (geom-point(size: 2.5pt, alpha: 0.85),),
  facet: facet-wrap("cyl", ncolumn: 3, labeller: label-both()),
  guides: guides(colour: none),
  labels: labels(
    title: "Highway mpg per Cylinder Count",
    subtitle: "label-both() prefixes each strip with the facet variable name",
    x: "Displacement (L)",
    y: "Highway mpg",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
