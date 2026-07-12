// Regression: a non-identity position over an `as-factor` positional column
// that is *also* mapped to colour/fill must keep the source column's raw
// levels, so the colour scale trains discrete and per-row lookups resolve the
// mapped palette instead of collapsing to the default (the "black points" bug).

#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/scale/train.typ": train
#import "../../src/data.typ": as-factor
#import "../../src/aes.typ": aes
#import "../../src/geom/jitter.typ": geom-jitter
#import "../../src/position/jitter.typ": position-jitter

// String levels so the colour scale is genuinely discrete (the case the bug
// broke: the in-place rewrite turned the strings into 1, 2, 3).
#let raw = (
  (grp: "a", hwy: 25),
  (grp: "b", hwy: 22),
  (grp: "a", hwy: 27),
  (grp: "c", hwy: 18),
  (grp: "b", hwy: 23),
)

// x forced discrete via `as-factor`, colour mapped to the same column.
#let mapping = aes(x: as-factor("grp"), y: "hwy", colour: "grp")
#let pos-col = "_gribouille-pos-grp"
#let layers = (geom-jitter(position: position-jitter(width: 0.12, seed: 1)),)
#let prepared = layers.map(l => _prepare-layer(l, mapping, raw))

// x is repointed to the synthetic numeric column; colour still points at the
// untouched source column.
#assert.eq(prepared.at(0).mapping.x.var, pos-col)
#assert.eq(prepared.at(0).mapping.colour, "grp")
// Every row keeps its raw `grp` level for the colour resolver to read.
#for row in prepared.at(0).data {
  assert(row.grp in ("a", "b", "c"))
}

#let trained = train(layers: prepared, mapping: mapping, data: raw)
// x stays discrete (anchored on levels) and, crucially, colour trains
// discrete over the raw levels rather than over the synthetic 1, 2, 3.
#assert.eq(trained.x.type, "discrete")
#assert.eq(trained.colour.type, "discrete")
#assert.eq(trained.colour.domain, ("a", "b", "c"))

as-factor + jitter + shared colour column tests passed.
