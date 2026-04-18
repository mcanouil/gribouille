// Same scatter rendered in three themes side-by-side.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let pts = (
  (x: 1.0, y: 2.1, g: "a"),
  (x: 2.0, y: 3.0, g: "a"),
  (x: 3.0, y: 4.2, g: "a"),
  (x: 4.0, y: 5.3, g: "a"),
  (x: 5.0, y: 6.1, g: "a"),
  (x: 1.5, y: 1.4, g: "b"),
  (x: 2.5, y: 2.3, g: "b"),
  (x: 3.5, y: 3.1, g: "b"),
  (x: 4.5, y: 4.2, g: "b"),
  (x: 5.5, y: 5.0, g: "b"),
)

#grid(
  columns: 3,
  column-gutter: 0.3cm,
  plot(
    data: pts,
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(size: 2.5pt),),
    theme: theme-minimal(),
    width: 6cm,
    height: 6cm,
  ),
  plot(
    data: pts,
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(size: 2.5pt),),
    theme: theme-classic(),
    width: 6cm,
    height: 6cm,
  ),
  plot(
    data: pts,
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(size: 2.5pt),),
    theme: theme-void(),
    width: 6cm,
    height: 6cm,
  ),
)
