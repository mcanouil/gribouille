// `geom-tile` accepts discrete and continuous axes in any combination. The
// discrete branch maps the cell centre via the trained scale and offsets the
// edges by `discrete-slot-width * width / 2` (panel-cm), so a default
// `width: 1` tile fills exactly one slot.

#import "../../src/scale/train.typ": discrete-slot-width, train
#import "../../src/scale/discrete.typ": scale-x-discrete, scale-y-discrete
#import "../../src/render/domain.typ": _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/tile.typ": geom-tile
#import "../../src/aes.typ": aes

// --- discrete x, discrete y ---

#let dd-data = (
  (x: "a", y: "p", v: 1),
  (x: "b", y: "p", v: 2),
  (x: "a", y: "q", v: 3),
  (x: "b", y: "q", v: 4),
)
#let dd-mapping = aes(x: "x", y: "y", fill: "v")
#let dd-layers = (geom-tile(),)
#let dd-prepared = dd-layers.map(l => _prepare-layer(l, dd-mapping, dd-data))
#let dd-trained = train(
  scales: (scale-x-discrete(), scale-y-discrete()),
  layers: dd-prepared,
  mapping: dd-mapping,
  data: dd-data,
)
#let dd-trained = _post-train(dd-trained, dd-prepared)
#assert.eq(dd-trained.x.type, "discrete")
#assert.eq(dd-trained.y.type, "discrete")
#assert.eq(dd-trained.x.domain, ("a", "b"))
#assert.eq(dd-trained.y.domain, ("p", "q"))

// `discrete-slot-width` honours the `view-index` produced by `_apply-expand`:
// the panel range is divided by `(n - 1) + 2 * DISCRETE-AUTO-DATA-PAD` rather
// than `n - 1`, since the auto pad widens the view-index window symmetrically.
#import "../../src/render/domain.typ": _apply-expand
#import "../../src/scale/expansion.typ": DISCRETE-AUTO-DATA-PAD
#let dd-expanded = _apply-expand(dd-trained, none)
#let slot = discrete-slot-width(dd-expanded.x, (0.0, 10.0))
#let view-span = (dd-expanded.x.domain.len() - 1) + 2 * DISCRETE-AUTO-DATA-PAD
#assert.eq(slot, 10.0 / view-span)

// --- discrete x, continuous y ---

#let dc-data = (
  (x: "a", y: 1, v: 1),
  (x: "a", y: 2, v: 2),
  (x: "b", y: 1, v: 3),
  (x: "b", y: 2, v: 4),
)
#let dc-mapping = aes(x: "x", y: "y", fill: "v")
#let dc-layers = (geom-tile(),)
#let dc-prepared = dc-layers.map(l => _prepare-layer(l, dc-mapping, dc-data))
#let dc-trained = train(
  scales: (scale-x-discrete(),),
  layers: dc-prepared,
  mapping: dc-mapping,
  data: dc-data,
)
#assert.eq(dc-trained.x.type, "discrete")
#assert.eq(dc-trained.y.type, "continuous")

// --- continuous x, continuous y (regression: still works) ---

#let cc-data = (
  (x: 1, y: 1, v: 1),
  (x: 2, y: 2, v: 2),
)
#let cc-mapping = aes(x: "x", y: "y", fill: "v")
#let cc-layers = (geom-tile(),)
#let cc-prepared = cc-layers.map(l => _prepare-layer(l, cc-mapping, cc-data))
#let cc-trained = train(
  layers: cc-prepared,
  mapping: cc-mapping,
  data: cc-data,
)
#assert.eq(cc-trained.x.type, "continuous")
#assert.eq(cc-trained.y.type, "continuous")

geom-tile discrete-axis tests passed.
