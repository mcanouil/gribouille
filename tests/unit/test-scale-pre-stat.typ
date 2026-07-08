// Pre-stat scale transforms. `scale-log10` rewrites layer rows in place
// before stats run, so the trained domain and downstream mapping operate in
// stat space. Mirrors plotnine semantics.

#import "../../src/aes.typ": aes
#import "../../src/render/prestat.typ": _preprocess-data
#import "../../src/scale/constructors.typ": scale-log10, scale-sqrt
#import "../../src/scales.typ": scales
#import "../../src/scale/train.typ": map-axis, map-axis-data, train

#let raw = (
  (x: 1, y: 1),
  (x: 10, y: 4),
  (x: 100, y: 9),
  (x: 1000, y: 16),
)
#let spec = (
  data: raw,
  mapping: aes(x: "x", y: "y"),
  layers: (
    (
      kind: "layer",
      name: "point",
      mapping: none,
      data: none,
      params: (:),
      stat: "identity",
      position: "identity",
      inherit-aes: true,
    ),
  ),
  scales: scales(x: scale-log10(), y: scale-sqrt()),
)

#let pre-spec = _preprocess-data(spec)
#let prepped = pre-spec.layers.at(0).data
#assert.eq(prepped.at(0).x, 0.0)
#assert.eq(prepped.at(3).x, 3.0)
#assert.eq(prepped.at(0).y, 1.0)
#assert.eq(prepped.at(3).y, 4.0)

#let trained = train(
  scales: pre-spec.scales,
  layers: pre-spec.layers,
  mapping: pre-spec.mapping,
  data: pre-spec.data,
)
#assert.eq(trained.x.pre-transformed, true)
#assert.eq(trained.x.transform, "log10")
#assert.eq(trained.x.domain, (0.0, 3.0))
#assert.eq(trained.y.pre-transformed, true)
#assert.eq(trained.y.transform, "sqrt")
#assert.eq(trained.y.domain, (1.0, 4.0))

// map-axis treats input as stat-space.
#assert.eq(map-axis(trained.x, 1.5, (0.0, 10.0)), 5.0)
// map-axis-data accepts data-space and applies the forward warp first.
#let mid = calc.pow(10, 1.5)
#assert(calc.abs(map-axis-data(trained.x, mid, (0.0, 10.0)) - 5.0) < 1e-9)

// Scales with no pre-stat transform leave the row data alone.
#let no-pre = _preprocess-data((
  data: raw,
  mapping: aes(x: "x", y: "y"),
  layers: (
    (
      kind: "layer",
      name: "point",
      mapping: none,
      data: none,
      params: (:),
      stat: "identity",
      position: "identity",
      inherit-aes: true,
    ),
  ),
  scales: (:),
))
#assert.eq(no-pre.layers.at(0).at("data", default: none), none)

Pre-stat scale-transform tests passed.
