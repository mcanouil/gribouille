// `spec.extents` of `geom-tile` reports the tile edges, and `_post-train`
// folds them into the continuous position domains so edge tiles stay inside
// the panel. Discrete axes keep their trained domain, and under free facet
// scales each panel pads from its own tiles only.

#import "../../src/scale/train.typ": train
#import "../../src/render/domain.typ": _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/tile.typ": geom-tile, spec as tile-spec
#import "../../src/aes.typ": aes
#import "../../src/data.typ": as-factor

#let approx(a, b) = calc.abs(a - b) < 1e-9
#let approx-pair(got, want) = (
  got != none
    and approx(got.at(0), want.at(0))
    and approx(got.at(1), want.at(1))
)

#let grid-data = (
  (x: 0, y: 0),
  (x: 1, y: 0),
  (x: 2, y: 0),
  (x: 0, y: 1),
  (x: 1, y: 1),
  (x: 2, y: 1),
)

#let trained-for(layer, mapping, data) = {
  let prepared = (_prepare-layer(layer, mapping, data),)
  let trained = train(layers: prepared, mapping: mapping, data: data)
  (trained: trained, prepared: prepared)
}

// --- the hook reports the tile edges ---

#assert(
  type(tile-spec.extents) == function,
  message: "tile has no extents hook",
)
#let ext = (tile-spec.extents)(
  (width: 0.9, height: 0.3),
  (x: "x", y: "y"),
  grid-data,
)
#assert(approx-pair(ext.x, (-0.45, 2.45)), message: repr(ext))
#assert(approx-pair(ext.y, (-0.15, 1.15)), message: repr(ext))

// --- `_post-train` widens the trained domains to the edges ---

#let fixed-mapping = aes(x: "x", y: "y")
#let fixed = trained-for(
  geom-tile(width: 0.9, height: 0.3),
  fixed-mapping,
  grid-data,
)
#assert.eq(fixed.trained.x.domain, (0, 2))
#let fixed-post = _post-train(fixed.trained, fixed.prepared)
#assert(approx-pair(fixed-post.x.domain, (-0.45, 2.45)), message: repr(
  fixed-post.x.domain,
))
#assert(approx-pair(fixed-post.y.domain, (-0.15, 1.15)), message: repr(
  fixed-post.y.domain,
))

// --- a mapped width is read through the mapping ---

#let mapped-data = (
  (x: 0, y: 0, w: 0.2),
  (x: 1, y: 0, w: 0.2),
  (x: 2, y: 0, w: 0.8),
)
#let mapped-mapping = aes(x: "x", y: "y", width: "w")
#let mapped = trained-for(geom-tile(), mapped-mapping, mapped-data)
#let mapped-post = _post-train(mapped.trained, mapped.prepared)
#assert(approx(mapped-post.x.domain.at(1), 2.4), message: repr(
  mapped-post.x.domain,
))
#assert(approx(mapped-post.x.domain.at(0), -0.1), message: repr(
  mapped-post.x.domain,
))

// --- a column literally named `width` pads x once, not twice ---

#let literal-data = (
  (x: 0, y: 0, width: 0.8),
  (x: 2, y: 0, width: 0.8),
)
#let literal = trained-for(
  geom-tile(),
  aes(x: "x", y: "y", width: "width"),
  literal-data,
)
#let literal-post = _post-train(literal.trained, literal.prepared)
#assert(approx-pair(literal-post.x.domain, (-0.4, 2.4)), message: repr(
  literal-post.x.domain,
))

// --- a row whose mapped width is `none` or not a number is skipped ---

#let gap-data = (
  (x: 0, y: 0, w: 0.2),
  (x: 1, y: 0, w: 0.2),
  (x: 5, y: 0, w: none),
  (x: 6, y: 0, w: "wide"),
)
#let gap-ext = (tile-spec.extents)(
  (width: 1, height: 1),
  (x: "x", y: "y", width: "w"),
  gap-data,
)
#assert(approx-pair(gap-ext.x, (-0.1, 1.1)), message: repr(gap-ext))
#let gap = trained-for(geom-tile(), mapped-mapping, gap-data)
#let gap-post = _post-train(gap.trained, gap.prepared)
#assert(approx-pair(gap-post.x.domain, (-0.1, 6)), message: repr(
  gap-post.x.domain,
))

// --- an axis with no numeric value reports `none` ---

#let none-ext = (tile-spec.extents)(
  (width: 1, height: 1),
  (x: "x", y: "y", width: "w"),
  ((x: 0, y: 0, w: none),),
)
#assert.eq(none-ext.x, none)
#assert.eq(none-ext.y, none)

// --- a discrete axis keeps its trained domain ---

#let factor-mapping = aes(x: as-factor("x"), y: "y")
#let factor = trained-for(
  geom-tile(width: 0.9, height: 0.3),
  factor-mapping,
  grid-data,
)
#assert.eq(factor.trained.x.type, "discrete")
#let factor-post = _post-train(factor.trained, factor.prepared)
#assert.eq(factor-post.x, factor.trained.x)
#assert(approx-pair(factor-post.y.domain, (-0.15, 1.15)), message: repr(
  factor-post.y.domain,
))

// --- free facet scales: each panel pads from its own tiles ---

#let left = grid-data.filter(r => r.x < 2)
#let right = grid-data.filter(r => r.x > 0).map(r => (x: r.x + 10, y: r.y))
#let left-panel = trained-for(
  geom-tile(width: 0.5, height: 0.3),
  fixed-mapping,
  left,
)
#let right-panel = trained-for(
  geom-tile(width: 0.5, height: 0.3),
  fixed-mapping,
  right,
)
#let left-post = _post-train(left-panel.trained, left-panel.prepared)
#let right-post = _post-train(right-panel.trained, right-panel.prepared)
#assert(approx-pair(left-post.x.domain, (-0.25, 1.25)), message: repr(
  left-post.x.domain,
))
#assert(approx-pair(right-post.x.domain, (10.75, 12.25)), message: repr(
  right-post.x.domain,
))

geom extents tests passed.
