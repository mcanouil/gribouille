// scale-stroke: marker outline thickness driven by the stroke aesthetic.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#let cont = range(1, 8).map(i => (x: i, y: i, w: i))

#let manual = (
  (x: 1, y: 1, g: "thin"),
  (x: 2, y: 2, g: "thin"),
  (x: 1, y: 2, g: "medium"),
  (x: 2, y: 3, g: "medium"),
  (x: 1, y: 3, g: "thick"),
  (x: 2, y: 4, g: "thick"),
)

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  plot(
    data: cont,
    mapping: aes(x: "x", y: "y", stroke: "w"),
    layers: (geom-point(size: 6pt, fill: accent),),
    scales: (scale-stroke-continuous(range: (0.2pt, 2pt)),),
    labels: labels(
      title: "Scale-Stroke-Continuous",
      x: "X",
      y: "Y",
      stroke: "w",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: manual,
    mapping: aes(x: "x", y: "y", stroke: "g"),
    layers: (geom-point(size: 6pt, fill: accent),),
    scales: (
      scale-stroke-manual(
        values: (0.2pt, 0.8pt, 2pt),
        limits: ("thin", "medium", "thick"),
      ),
    ),
    labels: labels(
      title: "Scale-Stroke-Manual",
      x: "X",
      y: "Y",
      stroke: "Outline",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
