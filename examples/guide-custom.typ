// guide-custom drops arbitrary Typst content into the legend area alongside
// the auto-built colour swatch.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "Setosa"),
  (x: 2, y: 2, g: "Versicolor"),
  (x: 3, y: 3, g: "Virginica"),
  (x: 4, y: 4, g: "Setosa"),
  (x: 5, y: 5, g: "Versicolor"),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 3pt),),
  guides: guides(
    note: guide-custom(
      [
        #set text(size: 7pt)
        Petal-length subset; rows for the original Anderson sample. Refresh quarterly.
      ],
      width: 3cm,
      height: auto,
      title: "Notes",
    ),
  ),
  labels: labels(title: "Guide-Custom: Free-Form Legend Slot"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
