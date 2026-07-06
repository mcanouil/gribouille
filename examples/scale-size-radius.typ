// scale-manual and scale-radius alongside the existing area variant.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#let cont = range(1, 8).map(i => (x: i, y: i, w: i * i))

#let manual = (
  (x: 1, y: 1, g: "small"),
  (x: 2, y: 2, g: "small"),
  (x: 1, y: 2, g: "medium"),
  (x: 2, y: 3, g: "medium"),
  (x: 1, y: 3, g: "large"),
  (x: 2, y: 4, g: "large"),
)

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  plot(
    data: cont,
    mapping: aes(x: "x", y: "y", size: "w"),
    layers: (geom-point(fill: accent),),
    scales: scales(size: scale-radius(range: (1pt, 8pt))),
    labels: labels(title: "Scale-Radius (linear)", x: "X", y: "Y", size: "w"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: cont,
    mapping: aes(x: "x", y: "y", size: "w"),
    layers: (geom-point(fill: accent),),
    scales: scales(size: scale-area(range: (1pt, 8pt))),
    labels: labels(title: "Scale-Size-Area (sqrt)", x: "X", y: "Y", size: "w"),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: manual,
    mapping: aes(x: "x", y: "y", size: "g"),
    layers: (geom-point(fill: accent),),
    scales: scales(size: scale-manual(values: (2pt, 4pt, 8pt),
        limits: ("small", "medium", "large"),)),
    labels: labels(
      title: "Scale-Size-Manual",
      x: "X",
      y: "Y",
      size: "Magnitude",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
