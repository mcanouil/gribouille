// A binning or counting stat with no x mapping returns no rows.
//
// Every panel maps only `y` on the first layer. The histogram, bar, dot plot,
// and step layers need `x`, so each draws no mark, and the red points set the
// scales alone. Before the fix, these stats passed the raw rows through, so the
// rows reached the geoms and changed the scales and gridlines.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = ((x: 1, y: 2), (x: 2, y: 4), (x: 3, y: 3), (x: 4, y: 5))

#grid(
  columns: 2,
  gutter: 0.5cm,
  ..(
    geom-histogram(),
    geom-bar(),
    geom-dotplot(),
    geom-step(stat: stat-connect()),
  ).map(layer => plot(
    data: d,
    mapping: aes(y: "y"),
    layers: (layer, geom-point(mapping: aes(x: "x"), colour: red)),
    width: 6cm,
    height: 4cm,
  )),
)
