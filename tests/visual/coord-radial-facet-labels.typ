// Smoke render: which tick labels a faceted radial panel keeps. A facet grid
// draws the x labels on its bottom row only and the y labels on its first
// column only, so read each grid for the axis those flags reach: the angular
// labels must follow the sweep, `x` on a rose and `y` on a pie, and the radial
// labels the other scale.

#import "../../lib.typ": *

#let rose = (
  (k: 0, v: 4, g: "one"),
  (k: 1, v: 6, g: "one"),
  (k: 2, v: 3, g: "one"),
  (k: 0, v: 5, g: "two"),
  (k: 1, v: 2, g: "two"),
  (k: 2, v: 7, g: "two"),
  (k: 0, v: 3, g: "three"),
  (k: 1, v: 5, g: "three"),
  (k: 2, v: 4, g: "three"),
  (k: 0, v: 6, g: "four"),
  (k: 1, v: 4, g: "four"),
  (k: 2, v: 2, g: "four"),
)

#let pie = (
  (slice: "all", value: 5, part: "a", g: "one"),
  (slice: "all", value: 3, part: "b", g: "one"),
  (slice: "all", value: 4, part: "a", g: "two"),
  (slice: "all", value: 4, part: "b", g: "two"),
  (slice: "all", value: 6, part: "a", g: "three"),
  (slice: "all", value: 2, part: "b", g: "three"),
  (slice: "all", value: 3, part: "a", g: "four"),
  (slice: "all", value: 5, part: "b", g: "four"),
)

#grid(
  columns: 1,
  row-gutter: 0.6cm,
  plot(
    data: rose,
    mapping: aes(x: "k", y: "v"),
    layers: (geom-col(width: 1),),
    coord: coord-radial(theta: "x"),
    facet: facet-wrap("g", ncolumn: 2),
    labels: labels(title: "Rose: angular labels on x, radial on y"),
    width: 12cm,
    height: 10cm,
  ),
  plot(
    data: pie,
    mapping: aes(x: "slice", y: "value", fill: "part"),
    layers: (geom-col(width: 1, position: "stack"),),
    coord: coord-radial(theta: "y"),
    scales: scales(y: scale-continuous(expand: false)),
    facet: facet-wrap("g", ncolumn: 2),
    guides: guides(fill: none),
    labels: labels(title: "Pie: angular labels on y, radial on x"),
    width: 12cm,
    height: 10cm,
  ),
)
