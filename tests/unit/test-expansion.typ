// Scale expansion plumbing.

#import "../../src/scale/expansion.typ": (
  DISCRETE-AUTO-DATA-PAD, normalise-expansion,
)
#import "../../src/scale/train.typ": map-discrete, map-position, train
#import "../../src/scale/continuous.typ": scale-x-continuous, scale-y-continuous
#import "../../src/scale/discrete.typ": scale-x-discrete
#import "../../src/coord/cartesian.typ": coord-cartesian

// Auto resolves to the per-scale-type defaults: 5% mult on continuous, no
// mult or canvas-cm pad on discrete (the renderer adds the data-unit slot
// pad separately when `expand: auto`).
#assert.eq(normalise-expansion(auto, "continuous"), (0.05, 0, 0.05, 0))
#assert.eq(normalise-expansion(auto, "discrete"), (0, 0, 0, 0))

// Ratios resolve to mult-only.
#assert.eq(normalise-expansion(5%, "continuous"), (0.05, 0, 0.05, 0))
#assert.eq(normalise-expansion((0%, 10%), "continuous"), (0, 0, 0.1, 0))

// A per-side `auto` keeps the matching half of the per-scale default; the
// explicit side resolves normally.
#assert.eq(normalise-expansion((0%, auto), "continuous"), (0, 0, 0.05, 0))
#assert.eq(normalise-expansion((auto, 10%), "continuous"), (0.05, 0, 0.1, 0))
// Discrete defaults have no mult; the slot pad is added later in
// `_apply-expand`, so a per-side `auto` resolves to zero mult here.
#assert.eq(normalise-expansion((auto, 0%), "discrete"), (0, 0, 0, 0))

// Lengths resolve to canvas-cm-only.
#assert.eq(normalise-expansion(1cm, "continuous"), (0, 1, 0, 1))
#assert.eq(
  normalise-expansion((5pt, 10pt), "continuous"),
  (0, 5pt / 1cm, 0, 10pt / 1cm),
)

// Relative (length + ratio) carries both components per side.
#let r = normalise-expansion(5pt + 5%, "continuous")
#assert.eq(r.at(0), 0.05)
#assert.eq(r.at(1), 5pt / 1cm)
#assert.eq(r.at(2), 0.05)
#assert.eq(r.at(3), 5pt / 1cm)

// Mixed sides: ratio on one, length on the other.
#assert.eq(
  normalise-expansion((0%, 10pt), "continuous"),
  (0, 0, 0, 10pt / 1cm),
)

// false / none collapse to zero.
#assert.eq(normalise-expansion(false, "continuous"), (0, 0, 0, 0))
#assert.eq(normalise-expansion(none, "discrete"), (0, 0, 0, 0))

#assert.eq(DISCRETE-AUTO-DATA-PAD, 0.6)

// Discrete mapping with view-index places level i at integer position i,
// linearly interpolated through the supplied viewport.
#assert.eq(
  map-discrete("a", ("a", "b", "c"), (0.0, 10.0), view-index: (-0.6, 2.6)),
  10.0 * (0 - (-0.6)) / (2.6 - (-0.6)),
)
#assert.eq(
  map-discrete("c", ("a", "b", "c"), (0.0, 10.0), view-index: (-0.6, 2.6)),
  10.0 * (2 - (-0.6)) / (2.6 - (-0.6)),
)

// Without view-index, mapping retains the midpoint behaviour used by
// non-positional discrete scales (colour, fill, shape, ...).
#assert.eq(map-discrete("a", ("a", "b"), (0.0, 10.0)), 2.5)
#assert.eq(map-discrete("b", ("a", "b"), (0.0, 10.0)), 7.5)

// Bar layers anchor y=0 at the axis line. With `geom-col`, `_post-train`
// tags the y trained entry with `anchor-zero: "lo"`, and `_apply-expand`
// collapses the lower-side multiplicative expansion. The y=0 baseline maps
// to the panel bottom, not 4.5% above it.
#import "../../src/render/domain.typ": _apply-expand, _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/col.typ": geom-col
#import "../../src/aes.typ": aes
#import "../../src/scale/train.typ": _map-transform

#let bar-data = (
  (cat: "a", y: 3),
  (cat: "b", y: 5),
  (cat: "c", y: 2),
)
#let bar-layers = (geom-col(),)
#let bar-prepared = bar-layers.map(l => _prepare-layer(
  l,
  aes(x: "cat", y: "y"),
  bar-data,
))
#let bar-trained = train(
  layers: bar-prepared,
  mapping: aes(x: "cat", y: "y"),
  data: bar-data,
)
#let bar-trained = _post-train(bar-trained, bar-prepared)
#assert.eq(bar-trained.y.at("anchor-zero", default: none), "lo")

#let bar-trained = _apply-expand(bar-trained, none)
// Lower-side mult collapsed to 0; upper side still gets the 5% default.
#let (vt-lo, vt-hi) = bar-trained.y.view-transform
#assert.eq(vt-lo, 0)
#assert(vt-hi > 5)
// view-pad-cm is zero for an auto continuous scale.
#assert.eq(bar-trained.y.at("view-pad-cm"), (0, 0))

// Per-side `auto`: `expand: (auto, 10%)` on the anchored bar axis collapses
// the lo-side mult (auto + anchor) to 0, while the hi side honours the
// explicit 10%. Domain is (0, 5), so the upper bound lifts by 0.1 * 5 = 0.5.
#let bar-side-trained = train(
  scales: (scale-y-continuous(expand: (auto, 10%)),),
  layers: bar-prepared,
  mapping: aes(x: "cat", y: "y"),
  data: bar-data,
)
#let bar-side-trained = _post-train(bar-side-trained, bar-prepared)
#let bar-side-trained = _apply-expand(bar-side-trained, none)
#assert.eq(bar-side-trained.y.view-transform, (0, 5.5))

// `_map-transform` places y=0 exactly at the start of the panel range.
#assert.eq(_map-transform(bar-trained.y, 0, (0.0, 100.0)), 0.0)

// `geom-col(position: "fill")` anchors both ends: y=0 at the panel bottom
// and y=1 at the panel top, since fill stacks always live in `[0, 1]`.
#let fill-data = (
  (q: "Q1", p: "A", v: 6),
  (q: "Q1", p: "B", v: 4),
  (q: "Q2", p: "A", v: 3),
  (q: "Q2", p: "B", v: 7),
)
#let fill-mapping = aes(x: "q", y: "v", fill: "p")
#let fill-layers = (geom-col(position: "fill"),)
#let fill-prepared = fill-layers.map(l => _prepare-layer(
  l,
  fill-mapping,
  fill-data,
))
#let fill-trained = train(
  layers: fill-prepared,
  mapping: fill-mapping,
  data: fill-data,
)
#let fill-trained = _post-train(fill-trained, fill-prepared)
#assert.eq(fill-trained.y.at("anchor-zero"), "both")

#let fill-trained = _apply-expand(fill-trained, none)
#assert.eq(fill-trained.y.view-transform, (0, 1))

// Length on a continuous axis lands in view-pad-cm; view-transform collapses to
// the trained domain (no mult component).
#import "../../src/geom/point.typ": geom-point
#let pt-data = ((x: 1, y: 1), (x: 5, y: 5))
#let pt-mapping = aes(x: "x", y: "y")
#let pt-layers = (geom-point(),)
#let pt-prepared = pt-layers.map(l => _prepare-layer(l, pt-mapping, pt-data))
#let pt-trained = train(
  scales: (scale-x-continuous(expand: 5pt),),
  layers: pt-prepared,
  mapping: pt-mapping,
  data: pt-data,
)
#let pt-trained = _apply-expand(pt-trained, none)
#assert.eq(pt-trained.x.view-transform, (1, 5))
#assert.eq(pt-trained.x.at("view-pad-cm"), (5pt / 1cm, 5pt / 1cm))

// Under `coord-radial`, the radial axis (opposite of `theta`) drops its
// lo-side expansion to zero so bars meet at radius 0.
#import "../../src/coord/radial.typ": coord-radial

#let pie-data = (
  (slice: "all", value: 30, region: "A"),
  (slice: "all", value: 70, region: "B"),
)
#let pie-mapping = aes(x: "slice", y: "value", fill: "region")
#let pie-layers = (geom-col(width: 1, position: "stack"),)
#let pie-prepared = pie-layers.map(l => _prepare-layer(
  l,
  pie-mapping,
  pie-data,
))
#let pie-trained = train(
  layers: pie-prepared,
  mapping: pie-mapping,
  data: pie-data,
)
#let pie-trained = _post-train(pie-trained, pie-prepared)
#let pie-trained = _apply-expand(pie-trained, coord-radial(theta: "y"))
// Pie shape (theta: "y"): radial x drops the lo data pad; the geom-min-pad
// floor (= half the bar width) keeps the inner edge at radius 0.
#assert.eq(pie-trained.x.view-index, (-0.5, DISCRETE-AUTO-DATA-PAD))
#assert.eq(pie-trained.x.at("view-pad-cm"), (0, 0))

// Rose shape (theta: "x"): radial y lo collapses from -5% to 0; hi unchanged.
#let rose-data = (
  (h: 0, v: 10),
  (h: 1, v: 50),
  (h: 2, v: 30),
)
#let rose-mapping = aes(x: "h", y: "v")
#let rose-layers = (geom-point(),)
#let rose-prepared = rose-layers.map(l => _prepare-layer(
  l,
  rose-mapping,
  rose-data,
))
#let rose-trained = train(
  layers: rose-prepared,
  mapping: rose-mapping,
  data: rose-data,
)
#let rose-trained = _apply-expand(rose-trained, coord-radial())
#let (rvt-lo, rvt-hi) = rose-trained.y.view-transform
#assert.eq(rvt-lo, 10)
#assert(rvt-hi > 50)

// Explicit `expand:` on the radial scale wins over the radial override.
#let pinned-trained = train(
  scales: (scale-x-continuous(expand: (10%, 0%)),),
  layers: rose-prepared,
  mapping: rose-mapping,
  data: rose-data,
)
#let pinned-trained = _apply-expand(
  pinned-trained,
  coord-radial(theta: "y"),
)
#let (pvt-lo, pvt-hi) = pinned-trained.x.view-transform
#assert(pvt-lo < 0)

Expansion tests passed.
