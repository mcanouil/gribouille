// Smoke render: horizontal colourbar and size-ladder.
//
// Slice 4 only adds the horizontal codepath; the renderer still pins the
// legend to the right margin (multi-side drawing arrives in Slice 6). The
// goal here is to verify the horizontal swatch / colourbar / size-ladder
// branches compile and lay out without overlap when forced via
// `direction: "horizontal"`.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "b"),
  (x: 3, y: 3, g: "c"),
  (x: 4, y: 4, g: "d"),
)

#let swatch = plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 3pt),),
  guides: guides(colour: guide-legend(direction: "horizontal")),
  labels: labels(title: "swatch horizontal"),
  width: 9cm,
  height: 5cm,
)

#let cbar = plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", colour: "body-mass"),
  layers: (geom-point(size: 1.5pt),),
  guides: guides(colour: guide-legend(direction: "horizontal")),
  labels: labels(
    title: "colourbar horizontal",
    x: "Flipper length",
    y: "Body mass",
  ),
  width: 11cm,
  height: 5cm,
)

#let ladder = plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", size: "body-mass"),
  layers: (geom-point(),),
  guides: guides(size: guide-legend(direction: "horizontal")),
  labels: labels(
    title: "size ladder horizontal",
    x: "Flipper length",
    y: "Body mass",
  ),
  width: 11cm,
  height: 5cm,
)

#stack(dir: ttb, spacing: 0.6cm, swatch, cbar, ladder)
