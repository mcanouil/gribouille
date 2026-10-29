// `compose(collect: "all")` moves the keys that not every panel carries into
// the shared block.
//
// The left panel maps `fill` to a tile ramp, and the right panel maps `colour`
// and `shape` to two profile curves. No aesthetic is on both panels, so the
// default `auto` hoists nothing and each panel keeps its own key. Under
// `"all"`, the fill bar and the colour and shape key stack in one block at the
// right edge of the figure, in panel order. The bottom composition stacks two
// colour keys that do not merge, each with the levels of its own panel.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let grid-data = (
  x: (1, 2, 3, 1, 2, 3, 1, 2, 3),
  y: (1, 1, 1, 2, 2, 2, 3, 3, 3),
  z: (1, 4, 2, 5, 9, 3, 2, 6, 8),
)
#let curves = (
  x: (1, 2, 3, 4, 1, 2, 3, 4),
  y: (1, 3, 2, 4, 2, 1, 3, 2),
  g: ("up", "up", "up", "up", "down", "down", "down", "down"),
)

#let heatmap = defer(
  plot,
  data: grid-data,
  mapping: aes(x: "x", y: "y", fill: "z"),
  layers: (geom-tile(),),
)
#let profiles = defer(
  plot,
  data: curves,
  mapping: aes(x: "x", y: "y", colour: "g", shape: "g"),
  layers: (geom-line(), geom-point(size: 3pt)),
)
#let points(groups) = defer(
  plot,
  data: (x: range(groups.len()), y: range(groups.len()), g: groups),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 3pt),),
)

#stack(
  dir: ttb,
  spacing: 0.8cm,
  compose(heatmap, profiles, columns: 2, width: 14cm, height: 5cm),
  compose(
    heatmap,
    profiles,
    columns: 2,
    collect: "all",
    width: 14cm,
    height: 5cm,
  ),
  compose(
    points(("a", "b")),
    points(("p", "q", "r")),
    columns: 2,
    collect: "all",
    width: 14cm,
    height: 5cm,
  ),
)
