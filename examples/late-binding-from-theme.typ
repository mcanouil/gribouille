// Pin a layer's stroke colour to the active theme's ink and the marker
// fill to the theme's accent. `from-theme(...)` resolves once at layer
// prepare time, so the values follow whatever theme the plot picks up
// without hard-coding palette colours into the spec.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 2),
  (x: 2, y: 4),
  (x: 3, y: 3),
  (x: 4, y: 5),
  (x: 5, y: 4),
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    colour: from-theme("ink"),
    fill: from-theme("accent"),
  ),
  layers: (geom-point(size: 4pt, stroke: 0.6pt),),
  labels: labels(title: "Theme-Pinned Point Colours"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
