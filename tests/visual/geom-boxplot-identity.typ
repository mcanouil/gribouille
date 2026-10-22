// Smoke render: geom-boxplot draws boxes from pre-computed summaries.
//
// The left panel maps `lower`, `middle`, `upper`, `ymin` and `ymax` with
// `stat: "identity"`. The middle panel draws the same boxes from raw
// observations with the default stat. The right panel is the identity plot
// under coord-flip.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let summary = (
  (g: "a", lo: 1, mid: 2, up: 3, ymin: 0, ymax: 4),
  (g: "b", lo: 2, mid: 3.5, up: 5, ymin: 1, ymax: 6),
)

#let raw = (
  (g: "a", y: 0),
  (g: "a", y: 1),
  (g: "a", y: 2),
  (g: "a", y: 3),
  (g: "a", y: 4),
  (g: "b", y: 1),
  (g: "b", y: 2),
  (g: "b", y: 3.5),
  (g: "b", y: 5),
  (g: "b", y: 6),
)

#let identity-mapping = aes(
  x: "g",
  lower: "lo",
  middle: "mid",
  upper: "up",
  ymin: "ymin",
  ymax: "ymax",
)

#grid(
  columns: 3,
  column-gutter: 0.5cm,
  plot(
    data: summary,
    mapping: identity-mapping,
    layers: (geom-boxplot(stat: "identity"),),
    width: 5cm,
    height: 5cm,
  ),
  plot(
    data: raw,
    mapping: aes(x: "g", y: "y"),
    layers: (geom-boxplot(),),
    width: 5cm,
    height: 5cm,
  ),
  plot(
    data: summary,
    mapping: identity-mapping,
    layers: (geom-boxplot(stat: "identity"),),
    coord: coord-flip(),
    width: 5cm,
    height: 5cm,
  ),
)
