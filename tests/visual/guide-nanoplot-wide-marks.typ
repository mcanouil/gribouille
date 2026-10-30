// Bars, tiles and histogram bins in a nanoplot column whose domain ends at the
// bar centres. The axis must sit under the cells, with the marks cut at the
// column edge and not widened past it.
#import "../../lib.typ": *
#import "@preview/keisen:0.2.0" as keisen

#set page(width: auto, height: auto, margin: 0.4cm)
#set text(size: 7pt)

#let bars(values) = values.enumerate().map(((i, v)) => (x: i, y: v))
#let rows = (
  (name: "A", cells: bars((3, 5, 2, 6, 4, 7, 3, 5, 2, 4, 6))),
  (name: "B", cells: bars((1, 2, 6, 3, 2, 5, 7, 4, 3, 6, 5))),
)

#keisen.display-table(
  rows,
  keisen.table-stub(rowname: "name"),
  keisen.format-nanoplot(
    "cells",
    plot: nanoplot(
      mapping: aes(x: "x", y: "y"),
      layers: (geom-col(width: 0.8),),
      domain-field: "x",
    ),
    width: 5cm,
    height: 0.8cm,
    domain: (0, 10),
  ),
)
