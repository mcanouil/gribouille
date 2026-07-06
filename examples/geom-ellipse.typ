// geom-ellipse: parametric ellipses with mapped fill and rotation.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let regions = (
  (x0: 0.5, y0: 0.5, a: 1.4, b: 0.7, angle: 0, region: "Coastal"),
  (x0: 1.8, y0: 1.6, a: 0.9, b: 0.5, angle: calc.pi / 6, region: "Mountain"),
  (x0: -0.6, y0: 1.8, a: 0.7, b: 0.7, angle: 0, region: "Plateau"),
  (x0: 1.0, y0: -0.6, a: 1.1, b: 0.4, angle: -calc.pi / 8, region: "Valley"),
)

#plot(
  data: regions,
  mapping: aes(
    x0: "x0",
    y0: "y0",
    a: "a",
    b: "b",
    angle: "angle",
    fill: "region",
  ),
  layers: (geom-ellipse(alpha: 0.5, stroke: 0.6pt),),
  scales: scales(fill: scale-brewer(palette: "Set2")),
  coord: coord-fixed(),
  labels: labels(
    title: "Catchment Regions Sketched as Ellipses",
    subtitle: "Each ellipse is parameterised by centre, semi-axes, and rotation",
    x: "Easting (km)",
    y: "Northing (km)",
    fill: "Region",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
