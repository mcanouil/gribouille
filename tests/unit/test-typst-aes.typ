// End-to-end check that typst() inside aes() for grouping and position
// aesthetics renders the legend swatches and axis ticks as Typst markup
// while keeping the raw column values for scale training and mapping.

#import "../../lib.typ": aes, geom-col, geom-point, labels, plot, typst

// Grouping aesthetic: typst() on the colour aes evaluates the level
// strings as markup in the legend swatches, but the colour scale still
// trains on the raw values.
#let by-species = (
  (x: 1, y: 1, sp: "$alpha$"),
  (x: 2, y: 4, sp: "$beta$"),
  (x: 3, y: 9, sp: "$gamma$"),
)

#plot(
  data: by-species,
  mapping: aes(x: "x", y: "y", colour: typst("sp")),
  layers: (geom-point(size: 3pt),),
  width: 10cm,
  height: 6cm,
)

// Position aesthetic: typst() on the x aes evaluates the tick labels as
// markup; positioning still uses the raw column values.
#plot(
  data: by-species,
  mapping: aes(x: typst("sp"), y: "y"),
  layers: (geom-point(size: 3pt),),
  width: 10cm,
  height: 6cm,
)

// Fill aesthetic on a discrete bar chart: legend swatches eval markup.
#let counts = (
  (g: "$x_1$", n: 4),
  (g: "$x_2$", n: 7),
  (g: "$x_3$", n: 3),
)

#plot(
  data: counts,
  mapping: aes(x: "g", y: "n", fill: typst("g")),
  layers: (geom-col(),),
  labels: labels(fill: typst("Group $k$")),
  width: 10cm,
  height: 6cm,
)

typst() aes-mapping smoke test passed.
