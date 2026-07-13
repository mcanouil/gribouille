// A plain discrete (string) positional column is rewritten to the numeric
// level spine for value-mutating positions (beeswarm, jitter, jitterdodge)
// without an explicit `as-factor`, mirroring how violin/boxplot read discrete
// x directly. Levels are numbered in sorted order so the numeric spine aligns
// with the alphabetically sorted trained domain regardless of input order.

#import "../../src/render/prestat.typ": _rewrite-factor-cols
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/scale/train.typ": train
#import "../../src/data.typ": as-factor
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point
#import "../../src/position/beeswarm.typ": position-beeswarm

// --- unsorted string x rewritten to sorted level positions --------------------
// Rows appear as c, a, b: first-appearance order differs from sorted order, so
// this pins the sorted-numbering behaviour.
#let raw = (
  (grp: "c", y: 1.0),
  (grp: "a", y: 2.0),
  (grp: "b", y: 3.0),
  (grp: "a", y: 2.5),
)
#let pos-col = "_gribouille-pos-grp"
#let r = _rewrite-factor-cols(aes(x: "grp", y: "y"), raw)
// No `as-factor`, yet the inferred-discrete column is rewritten.
#assert.eq(r.repoint, (x: pos-col))
// Levels recorded in sorted order, not first-appearance (c, a, b).
#assert.eq(r.factor-levels, ((pos-col): ("a", "b", "c")))
// Positions index the sorted levels: a->1, b->2, c->3.
#assert.eq(r.data.at(0).at(pos-col), 3)
#assert.eq(r.data.at(1).at(pos-col), 1)
#assert.eq(r.data.at(2).at(pos-col), 2)
#assert.eq(r.data.at(3).at(pos-col), 1)
// The source column keeps its raw levels for other aesthetics.
#assert.eq(r.data.at(0).grp, "c")

// --- a numeric x is left continuous (not rewritten) ---------------------------
#let num-raw = ((x: 4, y: 1.0), (x: 6, y: 2.0), (x: 8, y: 3.0))
#let num-r = _rewrite-factor-cols(aes(x: "x", y: "y"), num-raw)
#assert.eq(num-r.repoint, (:))
#assert.eq(num-r.data, num-raw)

// --- end-to-end: beeswarm on plain string x trains a discrete domain ----------
#let layers = (geom-point(position: position-beeswarm(width: 0.25)),)
#let prepared = layers.map(l => _prepare-layer(l, aes(x: "grp", y: "y"), raw))
#assert.eq(prepared.at(0).at("_factor-levels"), ((pos-col): ("a", "b", "c")))
#assert.eq(prepared.at(0).mapping.x.var, pos-col)
// Swarm offsets stay within the level band [1, 3] ± width; source grp intact.
#for row in prepared.at(0).data {
  assert(row.at(pos-col) >= 1 - 0.25 - 1e-9)
  assert(row.at(pos-col) <= 3 + 0.25 + 1e-9)
  assert(row.grp in ("a", "b", "c"))
}

#let trained = train(
  layers: prepared,
  mapping: aes(x: "grp", y: "y"),
  data: raw,
)
#assert.eq(trained.x.type, "discrete")
#assert.eq(trained.x.domain, ("a", "b", "c"))

beeswarm discrete-x tests passed.
