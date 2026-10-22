// `spec.extents` of `geom-tile` reports the tile edges, and `_post-train`
// folds them into the continuous position domains so edge tiles stay inside
// the panel. Discrete axes keep their trained domain, and under free facet
// scales each panel pads from its own tiles only. The col, ellipse, and
// binned-row padding go through the same hook, and keep the domains that
// `_post-train` produced before they moved there.

#import "../../src/scale/train.typ": train
#import "../../src/render/domain.typ": _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/tile.typ": geom-tile, spec as tile-spec
#import "../../src/geom/col.typ": geom-col, spec as col-spec
#import "../../src/geom/ellipse.typ": geom-ellipse, spec as ellipse-spec
#import "../../src/geom/histogram.typ": geom-histogram
#import "../../src/geom/freqpoly.typ": geom-freqpoly
#import "../../src/geom/dotplot.typ": geom-dotplot, spec as dotplot-spec
#import "../../src/geom/line.typ": spec as line-spec
#import "../../src/geom/point.typ": geom-point
#import "../../src/aes.typ": aes
#import "../../src/data.typ": as-factor
#import "../../src/scales.typ": scales
#import "../../src/scale/constructors.typ": scale-continuous

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

// --- user `limits` win over the tile edges, reversed ones included ---

#let wide-data = range(0, 5).map(i => (x: i, y: 0))
#for limits in ((2, 3), (-5, 10), (5, 0)) {
  let mapping = aes(x: "x", y: "y")
  let prepared = (_prepare-layer(geom-tile(), mapping, wide-data),)
  let trained = train(
    scales: scales(x: scale-continuous(limits: limits)),
    layers: prepared,
    mapping: mapping,
    data: wide-data,
  )
  let post = _post-train(trained, prepared)
  assert.eq(post.x.domain, limits, message: "limits " + repr(limits))
}

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

// --- col, ellipse, and binned layers pad through their extents hook ---

#for (name, s) in (
  ("col", col-spec),
  ("ellipse", ellipse-spec),
  ("dotplot", dotplot-spec),
  ("line", line-spec),
) {
  assert(type(s.extents) == function, message: name + " has no extents hook")
}

#let post-domains(layers, mapping, data) = {
  let prepared = layers.map(l => _prepare-layer(l, mapping, data))
  let trained = train(layers: prepared, mapping: mapping, data: data)
  _post-train(trained, prepared)
}

// The values below are the `_post-train` domains from before the move.

#let col-data = ((x: 1, y: 3), (x: 2, y: 5), (x: 4, y: 2))
#let col-mapping = aes(x: "x", y: "y")
#let col-post = post-domains((geom-col(),), col-mapping, col-data)
#assert(approx-pair(col-post.x.domain, (0.55, 4.45)), message: repr(
  col-post.x.domain,
))
#assert(approx-pair(col-post.y.domain, (0, 5)), message: repr(
  col-post.y.domain,
))
#assert.eq(col-post.y.anchor-zero, "lo")
#let narrow-post = post-domains((geom-col(width: 0.5),), col-mapping, col-data)
#assert(approx-pair(narrow-post.x.domain, (0.75, 4.25)), message: repr(
  narrow-post.x.domain,
))

#let factor-col = post-domains(
  (geom-col(),),
  aes(x: as-factor("x"), y: "y"),
  col-data,
)
#assert.eq(factor-col.x.type, "discrete")
#assert(approx(factor-col.x.geom-min-pad, 0.45), message: repr(factor-col.x))

#let ell-data = (
  (x0: 0, y0: 0, a: 2, b: 1, angle: 0.5),
  (x0: 3, y0: 1, a: 1, b: 0.5, angle: 0),
)
#let ell-post = post-domains(
  (geom-ellipse(),),
  aes(x0: "x0", y0: "y0", a: "a", b: "b", angle: "angle"),
  ell-data,
)
#assert(approx-pair(ell-post.x.domain, (-1.8194651573476779, 4)), message: repr(
  ell-post.x.domain,
))
#assert(
  approx-pair(ell-post.y.domain, (-1.2998255810676256, 1.5)),
  message: repr(
    ell-post.y.domain,
  ),
)

#let bin-data = range(20).map(i => (v: calc.rem(i * 7, 13) * 0.5))
#let bin-mapping = aes(x: "v")
#let hist-post = post-domains((geom-histogram(bins: 5),), bin-mapping, bin-data)
#assert(approx-pair(hist-post.x.domain, (-0.6, 6.6)), message: repr(
  hist-post.x.domain,
))
#assert(approx-pair(hist-post.y.domain, (0, 6)), message: repr(
  hist-post.y.domain,
))
#let freq-post = post-domains((geom-freqpoly(bins: 5),), bin-mapping, bin-data)
#assert(approx-pair(freq-post.x.domain, (0, 6)), message: repr(
  freq-post.x.domain,
))
#assert(approx-pair(freq-post.y.domain, (3, 6)), message: repr(
  freq-post.y.domain,
))
#let dot-post = post-domains((geom-dotplot(bins: 5),), bin-mapping, bin-data)
#assert(approx-pair(dot-post.x.domain, (0, 6)), message: repr(
  dot-post.x.domain,
))
#assert(approx-pair(dot-post.y.domain, (0.5, 5.5)), message: repr(
  dot-post.y.domain,
))

// --- user `limits` keep every pinned side; an `auto` side takes extents ---

#let limited(layer, mapping, data, limits) = {
  let prepared = (_prepare-layer(layer, mapping, data),)
  let trained = train(
    scales: scales(x: scale-continuous(limits: limits)),
    layers: prepared,
    mapping: mapping,
    data: data,
  )
  _post-train(trained, prepared).x.domain
}
#for (layer, mapping, data, lo-auto) in (
  (geom-col(), col-mapping, col-data, 0.55),
  (geom-histogram(bins: 5), bin-mapping, bin-data, -0.6),
) {
  for limits in ((2, 3), (0, 10), (5, 0)) {
    assert.eq(
      limited(layer, mapping, data, limits),
      limits,
      message: layer.name + " limits " + repr(limits),
    )
  }
  let half = limited(layer, mapping, data, (auto, 3))
  assert(
    approx-pair(half, (lo-auto, 3)),
    message: layer.name + " limits (auto, 3): " + repr(half),
  )
}
#let ell-mapping = aes(x0: "x0", y0: "y0", a: "a", b: "b", angle: "angle")
#assert.eq(limited(geom-ellipse(), ell-mapping, ell-data, (0, 3)), (0, 3))
#let ell-half = limited(geom-ellipse(), ell-mapping, ell-data, (auto, 3))
#assert(approx-pair(ell-half, (-1.8194651573476779, 3)), message: repr(
  ell-half,
))
#let tile-half = limited(
  geom-tile(),
  aes(x: "x", y: "y"),
  wide-data,
  (auto, 3),
)
#assert(approx-pair(tile-half, (-0.5, 3)), message: repr(tile-half))

// --- a col layer pads from its own bars, not the whole domain ---

#let wide-post = post-domains(
  (
    geom-col(),
    geom-point(data: ((x: 1, y: 3), (x: 8, y: 2))),
  ),
  col-mapping,
  col-data,
)
#assert(approx-pair(wide-post.x.domain, (0.55, 8)), message: repr(
  wide-post.x.domain,
))

geom extents tests passed.
