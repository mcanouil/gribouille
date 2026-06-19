// Smoke test for the new nudge/segment surface on geom-text, geom-label,
// and geom-typst. Verifies constructor params land on the layer dict and
// end-to-end renders compile (the assertion is the compile itself).

#import "../../src/aes.typ": aes
#import "../../src/geom/text.typ": geom-text
#import "../../src/geom/label.typ": geom-label
#import "../../src/geom/typst.typ": geom-typst
#import "../../src/plot.typ": plot

// Constructor wires the new params through to `layer.params` with the same
// defaults across text/label/typst so users see a uniform surface.
#let t = geom-text(segment: true, arrow: true)
#assert.eq(t.params.segment, true)
#assert.eq(t.params.arrow, true)
#assert.eq(t.params.segment-stroke, 0.4pt)
#assert.eq(t.params.min-segment-length, 0.05)
#assert.eq(t.params.arrow-length, 4pt)
#assert.eq(t.params.box-padding, 0.05)

#let l = geom-label(segment: true)
#assert.eq(l.params.segment, true)
#assert.eq(l.params.arrow, false)
#assert.eq(l.params.box-padding, 0.05)

#let g = geom-typst(segment: true, arrow: true, arrow-length: 6pt)
#assert.eq(g.params.segment, true)
#assert.eq(g.params.arrow-length, 6pt)

// Nudge may be pinned as a constant param, not only mapped via `aes()`. A
// number is a data-unit offset, a length a canvas-unit offset.
#let lc = geom-label(nudge-x: 0.5, nudge-y: 0.3cm)
#assert.eq(lc.params.nudge-x, 0.5)
#assert.eq(lc.params.nudge-y, 0.3cm)

// Per-row nudge offsets in data units plus a connector that should route
// around its sibling.
#let d = (
  (x: 1, y: 2, lab: "a", nx: 0.6, ny: 0.4),
  (x: 2, y: 4, lab: "b", nx: -0.4, ny: 0.6),
  (x: 3, y: 3, lab: "c", nx: 0.4, ny: -0.6),
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    label: "lab",
    nudge-x: "nx",
    nudge-y: "ny",
  ),
  layers: (geom-text(segment: true),),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    label: "lab",
    nudge-x: "nx",
    nudge-y: "ny",
  ),
  layers: (geom-label(segment: true, arrow: true),),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: ((x: 1, y: 1), (x: 2, y: 2), (x: 3, y: 3)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-typst(label: [#math.alpha], segment: true),),
  width: 10cm,
  height: 6cm,
)

// Constant nudge param drives the offset with no nudge in the mapping,
// exercising the param-first branch in `compute-placements`.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab"),
  layers: (geom-label(nudge-x: 0.5, nudge-y: 0.4),),
  width: 10cm,
  height: 6cm,
)

geom-text/label/typst nudge + segment smoke test passed.
