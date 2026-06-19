// End-to-end check that `geom-typst(label: ...)` accepts a constant content
// block or markup string and draws it at every row in the layer's data,
// bypassing the column-bound `aes(label: ...)` path. The compile is the
// assertion: a wiring error would raise at render time.

#import "../../lib.typ": aes, annotate, geom-point, geom-typst, plot

#let d = (
  (x: 1, y: 1),
  (x: 2, y: 2),
  (x: 3, y: 3),
)

// Content block as a constant label.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 3pt),
    geom-typst(label: [#math.alpha], mapping: aes(nudge-y: 0.2cm)),
  ),
  width: 10cm,
  height: 6cm,
)

// Markup string as a constant label; geom-typst evaluates it as Typst.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 3pt),
    geom-typst(label: "$beta$", mapping: aes(nudge-y: 0.2cm)),
  ),
  width: 10cm,
  height: 6cm,
)

// Annotate with a content label uses the same path through geom-typst.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 3pt),
    annotate("typst", x: 2, y: 2.5, label: [*peak* at #math.gamma]),
  ),
  width: 10cm,
  height: 6cm,
)

geom-typst constant-label smoke test passed.
