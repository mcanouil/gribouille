// Identity scales: the column value IS the visual property.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let signals = (
  (x: 1, y: 2.4, c: "#1b9e77", s: "circle"),
  (x: 2, y: 4.1, c: "#d95f02", s: "triangle"),
  (x: 3, y: 3.2, c: "#7570b3", s: "diamond"),
  (x: 4, y: 5.1, c: "#e7298a", s: "square"),
  (x: 5, y: 4.6, c: "#66a61e", s: "cross"),
)

#plot(
  data: signals,
  mapping: aes(x: "x", y: "y", fill: "c", shape: "s"),
  layers: (geom-point(size: 4pt),),
  scales: (scale-colour-identity(), scale-shape-identity()),
  labels: labels(
    title: "Identity Scales Pass Column Values Straight to Aesthetics",
    subtitle: "Hex strings drive fill; shape names drive marker glyphs",
    x: "X",
    y: "Y",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
