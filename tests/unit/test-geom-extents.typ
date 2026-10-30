// `spec.extents` of `geom-tile` reports the tile edges, and `_post-train`
// folds them into the continuous position domains so edge tiles stay inside
// the panel. Discrete axes keep their trained domain, and under free facet
// scales each panel pads from its own tiles only. The col, ellipse, and
// binned-row padding go through the same hook, and keep the domains that
// `_post-train` produced before they moved there. Half a bin of padding
// comes from the binning stats, not from a data column named `width`.

#import "../../src/scale/train.typ": train
#import "../../src/coord/expand.typ": apply-expand
#import "../../src/render/domain.typ": _post-train
#import "../../src/scale/oob.typ": filter-oob, oob-plans
#import "../../src/geom/registry.typ": GEOM-CENTRES
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/tile.typ": geom-tile, spec as tile-spec
#import "../../src/geom/col.typ": geom-col, spec as col-spec
#import "../../src/geom/ellipse.typ": geom-ellipse, spec as ellipse-spec
#import "../../src/geom/histogram.typ": geom-histogram
#import "../../src/geom/freqpoly.typ": geom-freqpoly
#import "../../src/geom/dotplot.typ": geom-dotplot, spec as dotplot-spec
#import "../../src/geom/line.typ": geom-line, spec as line-spec
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

// --- user `limits` keep the tiles centred inside them, drawn whole ---

#let wide-data = range(0, 5).map(i => (x: i, y: 0))
#for (limits, want) in (
  ((2, 3), (1.5, 3.5)),
  ((-5, 10), (-5, 10)),
  ((5, 0), (5, -0.5)),
) {
  let mapping = aes(x: "x", y: "y")
  let prepared = (_prepare-layer(geom-tile(), mapping, wide-data),)
  let trained = train(
    scales: scales(x: scale-continuous(limits: limits)),
    layers: prepared,
    mapping: mapping,
    data: wide-data,
  )
  let post = _post-train(trained, prepared)
  assert(
    approx-pair(post.x.domain, want),
    message: "limits " + repr(limits) + ": " + repr(post.x.domain),
  )
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
) {
  assert(type(s.extents) == function, message: name + " has no extents hook")
}
#for (name, s) in (("dotplot", dotplot-spec), ("line", line-spec)) {
  assert.eq(s.extents, none, message: name + " pads from its stat only")
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
// The bins span 0 to 6 and the bars fill them, so x pads half a bin to the
// bin edges, not a whole bin.
#let hist-post = post-domains((geom-histogram(bins: 5),), bin-mapping, bin-data)
#assert(approx-pair(hist-post.x.domain, (0, 6)), message: repr(
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

// --- user `limits` choose the marks by centre; the axis covers them whole ---

#let limited-post(layer, mapping, data, limits) = {
  let prepared = (_prepare-layer(layer, mapping, data),)
  let trained = train(
    scales: scales(x: scale-continuous(limits: limits)),
    layers: prepared,
    mapping: mapping,
    data: data,
  )
  (trained: _post-train(trained, prepared), prepared: prepared)
}
#let limited(layer, mapping, data, limits) = (
  limited-post(layer, mapping, data, limits).trained.x.domain
)

#let six-data = range(1, 7).map(i => (x: i, y: i))
#let dodge-data = (
  range(1, 7).map(i => ((x: i, y: i, g: "a"), (x: i, y: i + 1, g: "b"))).join()
)
#let dodge-mapping = aes(x: "x", y: "y", fill: "g")
#for (layer, mapping, data, cases) in (
  (
    geom-col(),
    col-mapping,
    six-data,
    (
      ((2, 5), (1.55, 5.45)),
      ((0, 10), (0, 10)),
      ((5, 2), (5.45, 1.55)),
      ((auto, 3), (0.55, 3.45)),
    ),
  ),
  (
    geom-col(position: "dodge"),
    dodge-mapping,
    dodge-data,
    (
      ((2, 5), (1.55, 5.45)),
      ((0, 10), (0, 10)),
      ((5, 2), (5.45, 1.55)),
    ),
  ),
  (
    geom-histogram(bins: 5),
    bin-mapping,
    bin-data,
    (
      ((2, 5), (2, 5)),
      ((0, 10), (0, 10)),
      ((5, 2), (5, 2)),
      ((auto, 3), (0, 3.6)),
    ),
  ),
) {
  for (limits, want) in cases {
    let got = limited(layer, mapping, data, limits)
    assert(
      approx-pair(got, want),
      message: layer.name + " limits " + repr(limits) + ": " + repr(got),
    )
  }
}

// A dodged bar keeps the full width of its slot, inside the col extents.
#let dodged = limited-post(
  geom-col(position: "dodge"),
  dodge-mapping,
  dodge-data,
  (2, 5),
)
#for row in dodged.prepared.first().data.filter(r => r.x >= 2 and r.x <= 5) {
  let centre = row.x + row.at("_dodge-offset") * 0.9
  let half = 0.9 / 2 / row.at("_dodge-n")
  assert(
    centre - half >= dodged.trained.x.domain.at(0)
      and centre + half <= dodged.trained.x.domain.at(1),
    message: "dodged bar "
      + repr(row)
      + " outside "
      + repr(
        dodged.trained.x.domain,
      ),
  )
}

#let ell-mapping = aes(x0: "x0", y0: "y0", a: "a", b: "b", angle: "angle")
#assert(
  approx-pair(
    limited(geom-ellipse(), ell-mapping, ell-data, (0, 3)),
    (-1.8194651573476779, 4),
  ),
  message: repr(limited(geom-ellipse(), ell-mapping, ell-data, (0, 3))),
)
// The ellipse centred at x0 = 0 is outside (1, 3.5): it feeds neither axis.
#let ell-narrow = limited-post(geom-ellipse(), ell-mapping, ell-data, (1, 3.5))
#assert(approx-pair(ell-narrow.trained.x.domain, (1, 4)), message: repr(
  ell-narrow.trained.x.domain,
))
#assert(approx-pair(ell-narrow.trained.y.domain, (0.5, 1.5)), message: repr(
  ell-narrow.trained.y.domain,
))
#let ell-half = limited(geom-ellipse(), ell-mapping, ell-data, (auto, 3))
#assert(
  approx-pair(ell-half, (-1.8194651573476779, 4)),
  message: repr(
    ell-half,
  ),
)
#let tile-half = limited(
  geom-tile(),
  aes(x: "x", y: "y"),
  wide-data,
  (auto, 3),
)
#assert(approx-pair(tile-half, (-0.5, 3.5)), message: repr(tile-half))

// --- a mark centred just outside the limits feeds no extents ---

#let near-data = ((x: 1.6, y: 1),) + range(2, 7).map(i => (x: i, y: i))
#let near = limited-post(geom-col(), col-mapping, near-data, (2, 5))
#assert(approx-pair(near.trained.x.domain, (1.55, 5.45)), message: repr(
  near.trained.x.domain,
))

// The out-of-bounds cutoff stays at the limits, not at the widened view: the
// bar at 1.6 sits inside the widened domain but is still dropped.
#let near-view = apply-expand(near.trained)
#let near-kept = filter-oob(near.prepared, oob-plans(near-view))
#assert.eq(
  near-kept.layers.first().data.map(r => r.x),
  (2, 3, 4, 5),
  message: repr(near-kept.layers.first().data),
)
// An ellipse is kept or dropped by its centre `x0`.
#let ell-view = apply-expand(ell-narrow.trained)
#let ell-kept = filter-oob(
  ell-narrow.prepared,
  oob-plans(ell-view),
  centres: GEOM-CENTRES,
)
#assert.eq(
  ell-kept.layers.first().data.map(r => r.x0),
  (3,),
  message: repr(ell-kept.layers.first().data),
)

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

// --- a data column named `width` does not pad x ---

#let width-col-data = (
  (x: 1, y: 3, width: 1),
  (x: 2, y: 5, width: 1),
  (x: 4, y: 2, width: 1),
)
#let width-col-post = post-domains((geom-col(),), col-mapping, width-col-data)
#assert(approx-pair(width-col-post.x.domain, (0.55, 4.45)), message: repr(
  width-col-post.x.domain,
))
#let width-line-post = post-domains(
  (geom-line(),),
  col-mapping,
  width-col-data,
)
#assert(approx-pair(width-line-post.x.domain, (1, 4)), message: repr(
  width-line-post.x.domain,
))

// --- dodged bars of mixed `width` keep their whole slot inside x ---

// Mixed widths per x fill the whole gap between two x values, so the outer
// bars reach half a gap past the outer x values.
#let mixed-data = (
  range(1, 4)
    .map(i => (
      (x: i, y: i, g: "a", width: 0.3),
      (x: i, y: i + 1, g: "b", width: 0.7),
    ))
    .join()
)
#let mixed-post = post-domains(
  (geom-col(position: "dodge"),),
  dodge-mapping,
  mixed-data,
)
#assert(approx-pair(mixed-post.x.domain, (0.5, 3.5)), message: repr(
  mixed-post.x.domain,
))

// One width for every row splits each gap evenly, so the pad stays at the
// bar half-width.
#let uniform-post = post-domains(
  (geom-col(position: "dodge"),),
  dodge-mapping,
  mixed-data.map(r => r + (width: 0.5)),
)
#assert(approx-pair(uniform-post.x.domain, (0.55, 3.45)), message: repr(
  uniform-post.x.domain,
))

// A row with no `width` takes the layer width in dodge, so one group of
// 0.3 against the default 0.9 still fills the whole gap.
#let partial-post = post-domains(
  (geom-col(position: "dodge"),),
  dodge-mapping,
  mixed-data.map(r => if r.g == "a" { r } else {
    (x: r.x, y: r.y, g: r.g)
  }),
)
#assert(approx-pair(partial-post.x.domain, (0.5, 3.5)), message: repr(
  partial-post.x.domain,
))

geom extents tests passed.
