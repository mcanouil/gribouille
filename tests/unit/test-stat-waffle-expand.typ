// A `stat-waffle()` layer drops the automatic position expansion on both
// axes, so the grid sits flush with the panel. An `expand` set by the user
// on a scale still wins on the side the user set.

#import "../../src/scale/train.typ": train
#import "../../src/render/domain.typ": _apply-expand, _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/tile.typ": geom-tile, spec as tile-spec
#import "../../src/stat/waffle.typ": stat-waffle
#import "../../src/aes.typ": aes
#import "../../src/scales.typ": scales
#import "../../src/scale/constructors.typ": scale-continuous

#let approx(a, b) = calc.abs(a - b) < 1e-9
#let approx-pair(got, want) = (
  got != none
    and approx(got.at(0), want.at(0))
    and approx(got.at(1), want.at(1))
)

#let data = range(0, 12).map(i => (kind: if i < 7 { "a" } else { "b" }))
#let mapping = aes(fill: "kind")
#let layer = geom-tile(stat: stat-waffle(rows: 4), width: 0.9, height: 0.9)

#let expanded(user-scales) = {
  let prepared = (_prepare-layer(layer, mapping, data),)
  let trained = train(
    scales: user-scales,
    layers: prepared,
    mapping: mapping,
    data: data,
  )
  let post = _post-train(trained, prepared)
  let ext = (tile-spec.extents)(
    prepared.first().params,
    prepared.first().mapping,
    prepared.first().data,
  )
  (view: _apply-expand(post, none), ext: ext)
}

// --- automatic expansion is off on both axes ---

#let flush = expanded(scales())
#assert(approx-pair(flush.ext.x, (0.55, 3.45)), message: repr(flush.ext))
#assert(approx-pair(flush.ext.y, (0.55, 4.45)), message: repr(flush.ext))
#assert(approx-pair(flush.view.x.view-transform, flush.ext.x), message: repr(
  flush.view.x.view-transform,
))
#assert(approx-pair(flush.view.y.view-transform, flush.ext.y), message: repr(
  flush.view.y.view-transform,
))
#assert.eq(flush.view.x.view-pad-cm, (0, 0))
#assert.eq(flush.view.y.view-pad-cm, (0, 0))

// --- a user `expand` on both sides still applies ---

#let both = expanded(scales(x: scale-continuous(expand: 10%)))
#let span = 2.9
#assert(
  approx-pair(both.view.x.view-transform, (
    0.55 - 0.1 * span,
    3.45 + 0.1 * span,
  )),
  message: repr(both.view.x.view-transform),
)
#assert(approx-pair(both.view.y.view-transform, both.ext.y), message: repr(
  both.view.y.view-transform,
))

// --- a user `expand` on one side applies there only ---

#let one = expanded(scales(x: scale-continuous(expand: (auto, 10%))))
#assert(
  approx-pair(one.view.x.view-transform, (0.55, 3.45 + 0.1 * span)),
  message: repr(one.view.x.view-transform),
)

stat-waffle expansion tests passed.
