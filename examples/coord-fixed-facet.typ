// coord-fixed combined with facet-wrap: every panel keeps a 1:1 unit ratio.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#let lines = ()
#for x in range(0, 11) {
  lines.push((line: "y = x", x: x, y: x))
  lines.push((line: "y = x + 1", x: x, y: x + 1))
  lines.push((line: "y = x − 1", x: x, y: x - 1))
}

#plot(
  data: lines,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-line(stroke: 1pt, colour: accent),
    geom-point(size: 2pt, fill: accent),
  ),
  facet: facet-wrap("line", ncolumn: 3),
  coord: coord-fixed(ratio: 1),
  labels: labels(
    title: "Coord-Fixed Inside Facet-Wrap",
    subtitle: "Every panel locks the same 1:1 ratio",
    x: "X",
    y: "Y",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
