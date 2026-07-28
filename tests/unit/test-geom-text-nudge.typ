// Smoke test for the new nudge/segment surface on geom-text, geom-label,
// and geom-typst. Verifies constructor params land on the layer dict and
// end-to-end renders compile (the assertion is the compile itself).

#import "../../src/aes.typ": aes
#import "../../src/geom/label-draw.typ": nudge-cm
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

// A numeric nudge alongside a discrete positional scale: the categorical
// anchor still projects, and a nudge on the discrete axis itself shifts in
// level units, matching `position-nudge`.

// Four levels over a 12cm panel put one slot at 3cm, so a one-level nudge on
// the discrete axis moves 3cm and a half-level nudge 1.5cm. The continuous
// axis spans 0..10 over 5cm, so a unit nudge moves 0.5cm. The categorical x
// must not block the y contribution.
#let cat-ctx = (
  trained: (
    x: (type: "discrete", domain: ("a", "b", "c", "d")),
    y: (type: "continuous", domain: (0, 10)),
  ),
  px-range: (0.0, 12.0),
  py-range: (0.0, 5.0),
)
#assert.eq(nudge-cm(cat-ctx, "a", 4, 1, 0), (3.0, 0.0))
#assert.eq(nudge-cm(cat-ctx, "a", 4, 0.5, 0), (1.5, 0.0))
#assert.eq(nudge-cm(cat-ctx, "a", 4, 0, 1), (0.0, 0.5))
#assert.eq(nudge-cm(cat-ctx, "a", 4, 0.5, 1), (1.5, 0.5))

// An anchor off the domain has no base point to offset from, so both axes
// contribute nothing. `compute-placements` drops such a row before it reaches
// here; the guard keeps the helper total for direct callers.
#assert.eq(nudge-cm(cat-ctx, "z", 4, 1, 1), (0.0, 0.0))

// A `length` nudge stays in canvas units on a categorical axis, unchanged.
#assert.eq(nudge-cm(cat-ctx, "a", 4, 0.7cm, 0), (0.7, 0.0))

#let cat = ((g: "a", v: 3), (g: "b", v: 5))

// Discrete x, nudge on the continuous axis.
#plot(
  data: cat,
  mapping: aes(x: "g", y: "v"),
  layers: (geom-text(mapping: aes(label: "v"), nudge-y: 1),),
  width: 6cm,
  height: 4cm,
)

// Discrete x, nudge on the discrete axis: half a slot to the right.
#plot(
  data: cat,
  mapping: aes(x: "g", y: "v"),
  layers: (geom-label(mapping: aes(label: "v"), nudge-x: 0.5),),
  width: 6cm,
  height: 4cm,
)

// Discrete y, nudge on the continuous axis.
#plot(
  data: cat,
  mapping: aes(x: "v", y: "g"),
  layers: (geom-text(mapping: aes(label: "g"), nudge-x: 1),),
  width: 6cm,
  height: 4cm,
)

// Both axes nudged with a discrete x, exercising the mixed path in one call.
#plot(
  data: cat,
  mapping: aes(x: "g", y: "v"),
  layers: (geom-label(mapping: aes(label: "v"), nudge-x: 0.25, nudge-y: 0.5),),
  width: 6cm,
  height: 4cm,
)

geom-text/label/typst nudge + segment smoke test passed.
