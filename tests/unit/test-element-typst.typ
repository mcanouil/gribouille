// Theme-driven Typst-markup passthrough via element-typst().
//
// element-typst() is a drop-in replacement for element-text() at any
// text surface. When set, plain strings reaching that surface are
// evaluated as Typst markup. Per-call typst() and content (`[...]`)
// values still pass through unchanged.

#import "../../lib.typ": (
  aes, element-text, element-typst, geom-col, geom-point, labels, plot, theme,
  typst,
)
#import "../../src/theme/defaults.typ": merge-theme

// Theme stores element records verbatim; element-typst keeps the kind tag
// while exposing the same fields as element-text.
#let t = theme(
  plot-title: element-typst(size: 14pt, weight: "bold"),
  axis-text: element-typst(),
  legend-title: element-text(),
)
#let merged = merge-theme(t)
#assert.eq(merged.plot-title.kind, "element-typst")
#assert.eq(merged.plot-title.size, 14pt)
#assert.eq(merged.plot-title.weight, "bold")
#assert.eq(merged.axis-text.kind, "element-typst")
#assert.eq(merged.legend-title.kind, "element-text")
#assert.eq(merged.plot-subtitle.kind, "element-text")

// Defaults: every text surface starts with element-text (not element-typst).
#let plain = merge-theme(none)
#assert.eq(plain.plot-title.kind, "element-text")
#assert.eq(plain.axis-text.kind, "element-text")
#assert.eq(plain.legend-text.kind, "element-text")
#assert.eq(plain.strip-text.kind, "element-text")

#let d = ((x: 1, y: 1), (x: 2, y: 4), (x: 3, y: 9))

// element-typst on plot-title: a plain-string title eval'd as markup.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(title: "Mean $macron(x)$ over time"),
  theme: theme(plot-title: element-typst(size: 14pt)),
  width: 10cm,
  height: 6cm,
)

// element-text fallback: same string renders literally (regression).
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(title: "Mean $macron(x)$ over time"),
  theme: theme(plot-title: element-text(size: 14pt)),
  width: 10cm,
  height: 6cm,
)

// Per-call typst() wins regardless of theme element.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(title: typst("$alpha + beta$")),
  theme: theme(plot-title: element-text()),
  width: 10cm,
  height: 6cm,
)

// Content passes through unchanged when element-typst is set
// (no double-eval since resolve-prose already keeps content as content).
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(title: [Bold *literal*]),
  theme: theme(plot-title: element-typst()),
  width: 10cm,
  height: 6cm,
)

// Mix and match: title is typst-eval'd, axis titles stay literal.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(
    title: "Result: $p < 0.001$",
    x: "Time (s)",
    y: "Distance (m)",
  ),
  theme: theme(
    plot-title: element-typst(),
    axis-title: element-text(),
  ),
  width: 10cm,
  height: 6cm,
)

// Discrete axis ticks with element-typst on axis-text.
#let groups = (
  (g: "$alpha$", n: 4),
  (g: "$beta$", n: 7),
  (g: "$gamma$", n: 3),
)
#plot(
  data: groups,
  mapping: aes(x: "g", y: "n", fill: "g"),
  layers: (geom-col(),),
  theme: theme(
    axis-text: element-typst(),
    legend-text: element-typst(),
  ),
  width: 10cm,
  height: 6cm,
)

element-typst smoke test passed.
