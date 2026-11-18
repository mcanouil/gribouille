// Smoke render: line geoms apply alpha once.
//
// geom-linerange, geom-errorbar, geom-rug and geom-path each draw red at
// alpha 0.5 over white. Their strokes must show the same opacity, about
// (255, 160, 154), and none may look lighter than the geom-path panel.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (g: "a", v: 1, lo: 1, hi: 3),
  (g: "b", v: 2, lo: 2, hi: 4),
)

#let panel(title, layer) = plot(
  data: d,
  mapping: aes(x: "g", y: "v", ymin: "lo", ymax: "hi"),
  layers: (layer,),
  guides: guides(default: none),
  width: 4cm,
  height: 3cm,
  labels: labels(title: title),
)

#grid(
  columns: 4,
  column-gutter: 4pt,
  panel("linerange", geom-linerange(colour: red, stroke: 6pt, alpha: 0.5)),
  panel("errorbar", geom-errorbar(colour: red, linewidth: 6pt, alpha: 0.5)),
  panel("rug", geom-rug(colour: red, linewidth: 6pt, alpha: 0.5)),
  panel("path", geom-path(colour: red, linewidth: 6pt, alpha: 0.5)),
)
