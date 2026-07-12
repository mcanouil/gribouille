// `as-factor("col")` paired with `position-jitter` writes 1-indexed level
// positions to a synthetic column before jitter runs, so the discrete domain
// stays anchored on the user's intended levels rather than collapsing onto
// the jittered floats. The source column is left intact so an aesthetic
// mapped to the same column (e.g. `colour: "cyl"`) still reads raw levels.

#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/render/prestat.typ": _rewrite-factor-cols
#import "../../src/scale/train.typ": map-discrete, train
#import "../../src/scale/constructors.typ": scale-discrete
#import "../../src/scales.typ": scales
#import "../../src/data.typ": as-factor
#import "../../src/aes.typ": aes
#import "../../src/geom/jitter.typ": geom-jitter
#import "../../src/position/jitter.typ": position-jitter

// --- _rewrite-factor-cols on a synthetic dataset ---

#let raw = (
  (cyl: 4, hwy: 25),
  (cyl: 6, hwy: 22),
  (cyl: 4, hwy: 27),
  (cyl: 8, hwy: 18),
  (cyl: 6, hwy: 23),
)

// Inline `as-factor("cyl")` — `_rewrite-factor-cols` writes 1-indexed
// integers to the synthetic `_gribouille-pos-cyl` column, records the
// original levels under that key, and repoints x to it, all while leaving
// the source `cyl` column untouched.
#let mapping = aes(x: as-factor("cyl"), y: "hwy")
#let pos-col = "_gribouille-pos-cyl"
#let r = _rewrite-factor-cols(mapping, raw)
#assert.eq(r.factor-levels, ((pos-col): ("4", "6", "8")))
#assert.eq(r.repoint, (x: pos-col))
#assert.eq(r.data.at(0).at(pos-col), 1)
#assert.eq(r.data.at(1).at(pos-col), 2)
#assert.eq(r.data.at(3).at(pos-col), 3)
// The source `cyl` column keeps its raw levels for other aesthetics.
#assert.eq(r.data.at(0).cyl, 4)
#assert.eq(r.data.at(3).cyl, 8)
// `hwy` is untouched.
#assert.eq(r.data.at(0).hwy, 25)

// Without `as-factor`, columns pass through unchanged and nothing is repointed.
#let plain-r = _rewrite-factor-cols(aes(x: "cyl", y: "hwy"), raw)
#assert.eq(plain-r.factor-levels, (:))
#assert.eq(plain-r.repoint, (:))
#assert.eq(plain-r.data, raw)

// --- end-to-end: `geom-jitter` + `as-factor` trains the right domain ---

#let layers = (
  geom-jitter(position: position-jitter(width: 0.12, seed: 1)),
)
#let prepared = layers.map(l => _prepare-layer(l, mapping, raw))
// The prepared layer carries the recorded levels keyed by the synthetic
// column, and its x mapping is repointed to that column.
#assert.eq(prepared.at(0).at("_factor-levels"), ((pos-col): ("4", "6", "8")))
#assert.eq(prepared.at(0).mapping.x.var, pos-col)
// Jitter writes fractional values around 1, 2, 3 to the synthetic column;
// the source `cyl` column keeps its raw levels.
#for row in prepared.at(0).data {
  assert(row.at(pos-col) >= 1 - 0.12 - 1e-9)
  assert(row.at(pos-col) <= 3 + 0.12 + 1e-9)
  assert(row.cyl in (4, 6, 8))
}

#let trained = train(layers: prepared, mapping: mapping, data: raw)
// Discrete domain comes from the recorded levels, not the jittered floats.
#assert.eq(trained.x.type, "discrete")
#assert.eq(trained.x.domain, ("4", "6", "8"))

// --- `map-discrete` accepts numeric values as fractional level positions ---

#let domain = ("4", "6", "8")
#let range = (0.0, 10.0)
// String lookup still works for raw values.
#assert.eq(map-discrete("4", domain, range), 10.0 / 6)
// Numeric integer maps to the same position as the level it indexes.
#assert.eq(map-discrete(1, domain, range), 10.0 / 6)
// Fractional value lands between adjacent levels.
#let mid = map-discrete(1.5, domain, range)
#let p1 = map-discrete(1, domain, range)
#let p2 = map-discrete(2, domain, range)
#assert.eq(mid, (p1 + p2) / 2)

as-factor + jitter tests passed.
