// A `stage`/`after-scale` marker that carries a `source` column trains the
// channel scale on that column (post `apply-stages`), so the per-row resolver
// hands the closure the scale-resolved value as `@after-scale` documents.
// Regression for #50: previously `train` skipped every late-binding marker,
// leaving the channel's domain empty and the closure receiving ink.

#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/scale/train.typ": train
#import "../../src/aes.typ": aes
#import "../../src/utils/late-binding.typ": after-scale, stage
#import "../../src/geom/point.typ": geom-point

#let raw = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "a"),
  (x: 3, y: 3, g: "b"),
  (x: 4, y: 4, g: "b"),
)

// A stage-derived after-scale marker trains its channel on the source column.
#let mapping-stage = aes(
  x: "x",
  y: "y",
  colour: stage(start: "g", after-scale: (c, _) => c),
)
#let prepared-stage = (_prepare-layer(geom-point(), mapping-stage, raw),)
#let trained-stage = train(
  layers: prepared-stage,
  mapping: mapping-stage,
  data: raw,
)
#assert.eq(trained-stage.colour.type, "discrete")
#assert.eq(trained-stage.colour.domain, ("a", "b"))

// A pure `after-scale` carries no source, so the channel scale stays untrained
// (the closure is expected to compute the value from `ctx`).
#let mapping-pure = aes(x: "x", y: "y", colour: after-scale((v, _) => v))
#let prepared-pure = (_prepare-layer(geom-point(), mapping-pure, raw),)
#let trained-pure = train(
  layers: prepared-pure,
  mapping: mapping-pure,
  data: raw,
)
#assert.eq(trained-pure.at("colour", default: none), none)

after-scale source training tests passed.
