// geom-text and geom-label: annotate points with their name.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let cities = (
  (x: 2.0, y: 5.3, name: "Alpha"),
  (x: 4.0, y: 2.8, name: "Beta"),
  (x: 6.0, y: 7.0, name: "Gamma"),
  (x: 8.0, y: 4.1, name: "Delta"),
)

#plot(
  data: cities,
  mapping: aes(x: "x", y: "y", label: "name"),
  layers: (
    geom-point(size: 4pt, fill: rgb("#1f77b4")),
    geom-text(size: 9pt, dy: 0.3, anchor: "south"),
  ),
  labs: labs(title: "Labelled points"),
  width: 10cm,
  height: 7cm,
)

#plot(
  data: cities,
  mapping: aes(x: "x", y: "y", label: "name"),
  layers: (
    geom-point(size: 4pt, fill: rgb("#1f77b4")),
    geom-label(size: 9pt, dy: 0.35, anchor: "south"),
  ),
  labs: labs(title: "Boxed labels"),
  width: 10cm,
  height: 7cm,
)
