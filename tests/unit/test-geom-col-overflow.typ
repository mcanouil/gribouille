// `geom-col` with a continuous category axis pads the trained domain by the
// bar half-width so the outer bars sit fully inside the panel rather than
// overflowing the x (or y under coord-flip) axis.

#import "../../src/scale/train.typ": train
#import "../../src/render/domain.typ": _col-half-width-x, _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/col.typ": geom-col
#import "../../src/aes.typ": aes

#let raw = (
  (sp: 1, y: 5.1),
  (sp: 2, y: 7.0),
  (sp: 3, y: 6.3),
)

// Default bar fraction is 0.9; minimum gap between unique x values is 1, so
// the expected half-width pad is 0.9 / 2 = 0.45 on each side.
#let layers = (geom-col(),)
#let prepared = layers.map(l => _prepare-layer(l, aes(x: "sp", y: "y"), raw))
#let trained = train(
  layers: prepared,
  mapping: aes(x: "sp", y: "y"),
  data: raw,
)
#let padded = _post-train(trained, prepared)
#assert.eq(padded.x.type, "continuous")
#let (lo, hi) = padded.x.domain
#assert(lo <= 1.0 - 0.45 + 1e-9)
#assert(hi >= 3.0 + 0.45 - 1e-9)

// A custom bar `width` shrinks the pad accordingly.
#let layers-narrow = (geom-col(width: 0.5),)
#let prepared-narrow = layers-narrow.map(l => _prepare-layer(
  l,
  aes(x: "sp", y: "y"),
  raw,
))
#let trained-narrow = train(
  layers: prepared-narrow,
  mapping: aes(x: "sp", y: "y"),
  data: raw,
)
#let padded-narrow = _post-train(trained-narrow, prepared-narrow)
#let (lo-n, hi-n) = padded-narrow.x.domain
#assert(lo-n <= 1.0 - 0.25 + 1e-9)
#assert(hi-n >= 3.0 + 0.25 - 1e-9)
// Narrower bars produce a tighter domain than wider bars.
#assert(lo-n > lo)
#assert(hi-n < hi)

// Discrete category axes are unchanged by the col padding pass.
#let raw-cat = (
  (sp: "a", y: 1),
  (sp: "b", y: 2),
  (sp: "c", y: 3),
)
#let layers-cat = (geom-col(),)
#let prepared-cat = layers-cat.map(l => _prepare-layer(
  l,
  aes(x: "sp", y: "y"),
  raw-cat,
))
#let trained-cat = train(
  layers: prepared-cat,
  mapping: aes(x: "sp", y: "y"),
  data: raw-cat,
)
#let padded-cat = _post-train(trained-cat, prepared-cat)
#assert.eq(padded-cat.x.type, "discrete")
#assert.eq(padded-cat.x.domain, ("a", "b", "c"))

// --- the half-width the padding comes from ---
// The gap is the smallest between two distinct x values, so repeats change
// nothing: a column that repeats every value pads exactly as the same column
// without the repeats does.
#let half-of(xs, frac: 0.9) = _col-half-width-x(((xs: xs, bar-frac: frac),))
#assert.eq(half-of((1.0, 2.0, 4.0)), 0.9 / 2)
#assert.eq(half-of((1.0, 1.0, 2.0, 2.0, 4.0, 4.0)), 0.9 / 2)
#assert.eq(half-of((4.0, 1.0, 2.0)), half-of((1.0, 2.0, 4.0)))

// A narrower bar takes a narrower pad, in proportion.
#assert.eq(half-of((1.0, 2.0), frac: 0.5), 0.5 / 2)

// One distinct value leaves no gap to measure, so nothing is padded, whether
// the column holds it once or many times.
#assert.eq(half-of((3.0,)), 0.0)
#assert.eq(half-of((3.0, 3.0, 3.0)), 0.0)
#assert.eq(half-of(()), 0.0)

// The widest half over every column layer wins, since one padding serves all.
#assert.eq(
  _col-half-width-x((
    (xs: (1.0, 2.0), bar-frac: 0.9),
    (xs: (0.0, 10.0, 20.0), bar-frac: 0.9),
  )),
  10.0 * 0.9 / 2,
)

geom-col continuous-axis padding tests passed.
