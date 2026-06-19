// geom-text and geom-label: annotate points with their name.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let cities = (
  (x: 2.0, y: 5.3, name: "Alpha"),
  (x: 4.0, y: 2.8, name: "Beta"),
  (x: 6.0, y: 7.0, name: "Gamma"),
  (x: 8.0, y: 4.1, name: "Delta"),
)

#let accent = rgb("#1f77b4")

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: cities,
    mapping: aes(x: "x", y: "y", label: "name"),
    layers: (
      geom-point(size: 4pt, fill: accent),
      geom-text(mapping: aes(nudge-y: 0.3cm), size: 9pt, anchor: "south"),
    ),
    scales: (scale-y-continuous(expand: (5%, 15%)),),
    labels: labels(title: "Geom-Text (plain)", x: "X", y: "Y"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: cities,
    mapping: aes(x: "x", y: "y", label: "name"),
    layers: (
      geom-point(size: 4pt, fill: accent),
      geom-label(mapping: aes(nudge-y: 0.35cm), size: 9pt, anchor: "south"),
    ),
    scales: (scale-y-continuous(expand: (5%, 15%)),),
    labels: labels(title: "Geom-Label (boxed)", x: "X", y: "Y"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
