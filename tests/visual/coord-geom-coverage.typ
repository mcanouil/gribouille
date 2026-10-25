// Smoke render: geoms under coord-radial, coord-flip, and coord-fixed.
//
// The first fifteen panels draw abline, boxplot, stacked col, dodged col,
// crossbar, dotplot, errorbar, hex, rect, hline plus vline, rug, path, polygon,
// segment, and area under coord-radial. The next four draw stacked col,
// boxplot, violin, and density-ridges under coord-flip. The last three are a
// free-scale facet-wrap under coord-flip, the same under coord-radial, and a
// coord-fixed ratio 2 scatter. Violin and density-ridges draw nothing under
// coord-radial, so they have no radial panel.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let pts = range(0, 12).map(i => (
  x: i,
  y: calc.sin(i * 0.5) * 3 + 4,
))
#let groups = range(0, 30).map(i => (
  g: ("a", "b", "c").at(calc.rem(i, 3)),
  v: calc.rem(i * 7, 11) + calc.rem(i, 3) * 2,
))
#let parts = (
  (q: "Q1", k: "u", n: 3),
  (q: "Q1", k: "w", n: 2),
  (q: "Q2", k: "u", n: 4),
  (q: "Q2", k: "w", n: 1),
  (q: "Q3", k: "u", n: 2),
  (q: "Q3", k: "w", n: 5),
)
#let ranges = range(1, 5).map(i => (
  x: i,
  y: i,
  lo: i - 0.6,
  hi: i + 0.6,
))
#let cloud = range(0, 300).map(i => (
  x: calc.sin(i * 0.13) * 4,
  y: calc.cos(i * 0.21) * 4,
))
#let boxes = (
  (x0: 0, x1: 2, y0: 0, y1: 3),
  (x0: 2, x1: 5, y0: 1, y1: 4),
  (x0: 5, x1: 6, y0: 0, y1: 2),
)
#let shape = (
  (x: 0, y: 0),
  (x: 4, y: 1),
  (x: 3, y: 4),
  (x: 1, y: 3),
)
#let spokes = range(0, 6).map(i => (
  x: i,
  y: 1,
  xe: i + 0.5,
  ye: 1 + i * 0.5,
))
#let ridges = {
  let xs = (1, 2, 2, 3, 3, 3, 4, 4, 5, 7)
  let d = ()
  for (i, grp) in ("a", "b", "c").enumerate() {
    for x in xs { d.push((grp: grp, x: x * (1 + i * 0.4) + i)) }
  }
  d
}
#let faceted = range(0, 24).map(i => (
  f: ("p", "q").at(calc.rem(i, 2)),
  x: i * (1 + calc.rem(i, 2)),
  y: calc.rem(i * 5, 7) * (1 + calc.rem(i, 2) * 3),
))

#let cell(data, mapping, layers, coord, ..rest) = plot(
  data: data,
  mapping: mapping,
  layers: layers,
  coord: coord,
  width: 4cm,
  height: 4cm,
  ..rest,
)

#let radial = coord-radial()
#let flip = coord-flip()

#grid(
  columns: 5,
  gutter: 0.3cm,
  cell(
    pts,
    aes(x: "x", y: "y"),
    (geom-point(size: 1.5pt), geom-abline(slope: 0.3, intercept: 2)),
    radial,
  ),
  cell(groups, aes(x: "g", y: "v"), (geom-boxplot(),), radial),
  cell(
    parts,
    aes(x: "q", y: "n", fill: "k"),
    (geom-col(position: "stack"),),
    radial,
  ),
  cell(
    parts,
    aes(x: "q", y: "n", fill: "k"),
    (geom-col(position: "dodge"),),
    radial,
  ),
  cell(
    ranges,
    aes(x: as-factor("x"), y: "y", ymin: "lo", ymax: "hi"),
    (geom-crossbar(),),
    radial,
  ),
  cell(pts, aes(x: "y"), (geom-dotplot(bins: 8),), radial),
  cell(
    ranges,
    aes(x: "x", ymin: "lo", ymax: "hi"),
    (geom-errorbar(width: 0.4),),
    radial,
  ),
  cell(cloud, aes(x: "x", y: "y"), (geom-hex(bins: 10),), radial),
  cell(
    boxes,
    aes(xmin: "x0", xmax: "x1", ymin: "y0", ymax: "y1"),
    (geom-rect(),),
    radial,
  ),
  cell(
    pts,
    aes(x: "x", y: "y"),
    (
      geom-point(size: 1.5pt),
      geom-hline(yintercept: 4),
      geom-vline(xintercept: 6),
    ),
    radial,
  ),
  cell(
    pts,
    aes(x: "x", y: "y"),
    (geom-point(size: 1.5pt), geom-rug(sides: "bl")),
    radial,
  ),
  cell(pts, aes(x: "x", y: "y"), (geom-path(),), radial),
  cell(shape, aes(x: "x", y: "y"), (geom-polygon(),), radial),
  cell(
    spokes,
    aes(x: "x", y: "y", xend: "xe", yend: "ye"),
    (geom-segment(),),
    radial,
  ),
  cell(pts, aes(x: "x", y: "y"), (geom-area(),), radial),
  cell(
    parts,
    aes(x: "q", y: "n", fill: "k"),
    (geom-col(position: "stack"),),
    flip,
  ),
  cell(groups, aes(x: "g", y: "v"), (geom-boxplot(),), flip),
  cell(groups, aes(x: "g", y: "v"), (geom-violin(),), flip),
  cell(ridges, aes(x: "x", y: "grp"), (geom-density-ridges(scale: 1.4),), flip),
  cell(
    faceted,
    aes(x: "x", y: "y"),
    (geom-point(size: 1.5pt),),
    flip,
    facet: facet-wrap("f", scales: "free"),
  ),
  cell(
    faceted,
    aes(x: "x", y: "y"),
    (geom-point(size: 1.5pt),),
    radial,
    facet: facet-wrap("f", scales: "free"),
  ),
  cell(
    pts,
    aes(x: "x", y: "y"),
    (geom-point(size: 1.5pt),),
    coord-fixed(ratio: 2),
  ),
)
