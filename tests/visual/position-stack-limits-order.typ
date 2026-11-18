// Stack order follows scale-discrete(limits:) on the fill.
//
// Each panel maps fill to a group and sets limits ("c", "b", "a"). The
// first limit sits on top of the stack, so the bands read c, b, a from the
// top and match the legend, top key first. The left panel is a geom-col and
// the right panel a geom-area.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let bars = (
  (k: "x", g: "a", v: 1),
  (k: "x", g: "b", v: 2),
  (k: "x", g: "c", v: 3),
)
#let series = range(1, 6).map(x => ((x: x, g: "a", v: 1), (x: x, g: "b", v: 2), (x: x, g: "c", v: 3))).flatten()
#let limits = scales(fill: scale-discrete(limits: ("c", "b", "a")))

#grid(
  columns: 2,
  gutter: 6pt,
  plot(
    data: bars,
    mapping: aes(x: "k", y: "v", fill: "g"),
    layers: (geom-col(position: "stack"),),
    scales: limits,
    width: 6cm,
    height: 5cm,
    labels: labels(title: "geom-col"),
  ),
  plot(
    data: series,
    mapping: aes(x: "x", y: "v", fill: "g"),
    layers: (geom-area(position: "stack"),),
    scales: limits,
    width: 6cm,
    height: 5cm,
    labels: labels(title: "geom-area"),
  ),
)
