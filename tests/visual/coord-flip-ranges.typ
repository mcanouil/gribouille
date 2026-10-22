// Smoke render: range, band, and density geoms follow coord-flip.
//
// Under coord-flip each geom draws along the user's x axis, which runs
// vertically, and spans the user's y axis, which runs horizontally: ranges,
// crossbars, boxplots, and violins lie on their level rows, and ribbons,
// areas, steps, smooth bands, and densities run up the panel. A dotplot keeps
// its dots on a reversed flip, and dodged pointranges on a continuous x keep
// their slots.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let r = (
  (g: "a", v: 2, lo: 1, hi: 3),
  (g: "b", v: 6, lo: 4, hi: 8),
  (g: "c", v: 4, lo: 3, hi: 5),
)
#let s = range(0, 24).map(i => (
  x: i / 2,
  y: calc.sin(i / 3) + calc.rem(i * 7, 5) / 5,
  g: if calc.rem(i, 2) == 0 { "a" } else { "b" },
))
#let two = (
  s.map(row => row + (g: "a", y: row.y + 1.5))
    + s.map(row => row + (g: "b", y: row.y + 2))
)

#let flipped(data, mapping, layer) = plot(
  data: data,
  mapping: mapping,
  layers: (layer,),
  coord: coord-flip(),
  width: 5cm,
  height: 4cm,
)

#grid(
  columns: 4,
  column-gutter: 0.5cm,
  row-gutter: 0.5cm,
  flipped(r, aes(x: "g", ymin: "lo", ymax: "hi"), geom-linerange()),
  flipped(r, aes(x: "g", y: "v", ymin: "lo", ymax: "hi"), geom-pointrange()),
  flipped(r, aes(x: "g", y: "v", ymin: "lo", ymax: "hi"), geom-crossbar()),
  flipped(s, aes(x: "g", y: "y"), geom-boxplot()),

  flipped(s, aes(x: "g", y: "y"), geom-violin()),
  flipped(s, aes(x: "x", ymin: "y", ymax: "x"), geom-ribbon()),
  flipped(two, aes(x: "x", y: "y", fill: "g"), geom-area()),
  flipped(s, aes(x: "x", y: "y"), geom-step()),

  flipped(s, aes(x: "x", y: "y"), geom-smooth()),
  flipped(s, aes(x: "y"), geom-density()),
  flipped(s, aes(x: "x", y: "y"), geom-hex()),
  flipped(s, aes(x: "y"), geom-dotplot()),

  flipped(
    s.map(row => row + (lo: row.y - 0.3, hi: row.y + 0.3)),
    aes(x: "x", y: "y", ymin: "lo", ymax: "hi", colour: "g"),
    geom-pointrange(position: position-dodge(width: 0.4)),
  ),
  plot(
    data: s,
    mapping: aes(x: "y"),
    layers: (geom-dotplot(),),
    coord: coord-flip(reverse: true),
    width: 5cm,
    height: 4cm,
  ),
)
