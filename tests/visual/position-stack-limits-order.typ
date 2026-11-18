// Stack order follows scale-discrete(limits:) on the fill.
//
// Each panel maps fill to a group and sets limits ("c", "b", "a"). The
// first limit sits on top of the stack, so the bands read c, b, a from the
// top and match the legend, top key first. The left panel is a geom-col and
// the right panel a geom-area. The second row repeats the geom-col with the
// group mapped to fill and colour, and to fill and linetype; the order stays
// c, b, a from the top.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let bars = (
  (k: "x", g: "a", v: 1),
  (k: "x", g: "b", v: 2),
  (k: "x", g: "c", v: 3),
)
#let series = range(1, 6).map(x => ((x: x, g: "a", v: 1), (x: x, g: "b", v: 2), (x: x, g: "c", v: 3))).flatten()
#let order = ("c", "b", "a")
#let limits = scales(fill: scale-discrete(limits: order))
#let limits-both = scales(
  fill: scale-discrete(limits: order),
  colour: scale-discrete(limits: order),
)
#let limits-linetype = scales(
  fill: scale-discrete(limits: order),
  linetype: scale-discrete(limits: order),
)

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
    height: 6cm,
    labels: labels(title: "geom-area"),
  ),
  plot(
    data: bars,
    mapping: aes(x: "k", y: "v", fill: "g", colour: "g"),
    layers: (geom-col(position: "stack"),),
    scales: limits-both,
    width: 6cm,
    height: 6cm,
    labels: labels(title: "fill and colour"),
  ),
  plot(
    data: bars,
    mapping: aes(x: "k", y: "v", fill: "g", linetype: "g"),
    layers: (geom-col(position: "stack"),),
    scales: limits-linetype,
    width: 6cm,
    height: 6cm,
    labels: labels(title: "fill and linetype"),
  ),
)
