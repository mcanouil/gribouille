// guide-legend(): customise per-aesthetic legends; pass `none` to suppress one.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let make-panel(title, gs) = plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", colour: "class"),
  layers: (geom-point(size: 2.5pt),),
  guides: gs,
  labs: labs(
    title: title,
    x: "Displacement (L)",
    y: "Highway mpg",
    colour: "Class",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  make-panel("default", (:)),
  make-panel("guide-legend(reverse: true)", guides(
    colour: guide-legend(reverse: true),
  )),
  make-panel("guide-legend(ncolumn: 2)", guides(
    colour: guide-legend(ncolumn: 2),
  )),
  make-panel(
    "guide-legend(position: \"bottom\")",
    guides(colour: guide-legend(position: "bottom")),
  ),
)
