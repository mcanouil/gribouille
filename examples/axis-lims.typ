// scale-*-continuous(limits:) sets explicit data domains; guide-axis tweaks tick text.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let base(title, extra-scales: (:), extra-guides: (:)) = plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (geom-point(size: 2.5pt, alpha: 0.7),),
  scales: extra-scales,
  guides: extra-guides,
  labels: labels(title: title, x: "Displacement (L)", y: "Highway mpg"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  base("default"),
  base(
    "guide-axis(angle: 45)",
    extra-guides: guides(x: guide-axis(angle: 45)),
  ),
  base(
    "limits: (0, 8) / (0, 50)",
    extra-scales: scales(x: scale-continuous(limits: (0, 8)), y: scale-continuous(limits: (0, 50))),
  ),
)
