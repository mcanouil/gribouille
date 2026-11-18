// position-beeswarm(method: "center"): count-based centred stacks.

#import "../../src/position/apply.typ": apply-position
#import "../../src/position/beeswarm.typ": _center-offsets, position-beeswarm

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol
#let close-all(actual, expected) = {
  assert.eq(actual.len(), expected.len())
  for (a, e) in actual.zip(expected) { assert(close(a, e)) }
}
#let run(d, mapping: (x: "x", y: "y"), ..args) = apply-position(
  "beeswarm",
  d,
  mapping,
  params: position-beeswarm(method: "center", ..args).params,
)

// --- offsets for one bin ------------------------------------------------------
#close-all(_center-offsets(1, 0.1), (0.0,))
#close-all(_center-offsets(2, 0.1), (0.05, -0.05))
#close-all(_center-offsets(3, 0.1), (0.0, 0.1, -0.1))
#close-all(_center-offsets(4, 0.1), (0.05, -0.05, 0.15, -0.15))

// --- shared step across rows --------------------------------------------------
#let two = (
  (x: 1, y: 0.1),
  (x: 1, y: 0.2),
  (x: 1, y: 0.3),
  (x: 2, y: 0.4),
)
#let r = run(two, binwidth: 1, spacing: 0.1).data
#close-all(r.map(row => row.x - 1).slice(0, 3), (0.0, 0.1, -0.1))
#assert(close(r.at(3).x, 2.0))

// --- points move to the bin centre --------------------------------------------
#let b = run(
  ((x: 1, y: 0.2), (x: 1, y: 0.7), (x: 2, y: 0.0)),
  binwidth: 1,
  spacing: 0.1,
).data
#assert(close(b.at(0).y, 0.5))
#assert(close(b.at(1).y, 0.5))

// --- value order, then input order --------------------------------------------
#let o = run(
  ((x: 1, y: 0.9), (x: 1, y: 0.1), (x: 1, y: 0.5)),
  binwidth: 1,
  spacing: 1,
).data
#close-all(o.map(row => row.x - 1), (-1.0, 0.0, 1.0))

// --- auto binwidth: range / 30, or 1 for a zero range -------------------------
#let a = run(((x: 1, y: 0), (x: 1, y: 30))).data
#assert(close(a.at(0).y, 0.5))
#assert(close(a.at(1).y, 30.5))
#let flat = run(((x: 1, y: 5), (x: 1, y: 5))).data
#assert(close(flat.at(0).y, 5.5))

// --- empty data ---------------------------------------------------------------
#assert.eq(run(()).data, ())

// --- orientation y ------------------------------------------------------------
#let ydata = (
  (x: 0.1, y: 1),
  (x: 0.2, y: 1),
  (x: 0.3, y: 1),
)
#let ry = run(ydata, binwidth: 1, spacing: 0.1, orientation: "y").data
#close-all(ry.map(row => row.y - 1), (0.0, 0.1, -0.1))
#for row in ry { assert(close(row.x, 0.6)) }

// --- width 0 does not disable the centre method ---------------------------------
#let w0 = run(
  ((x: 1, y: 0.1), (x: 1, y: 0.2)),
  width: 0,
  binwidth: 1,
  spacing: 0.1,
).data
#close-all(w0.map(row => row.x - 1), (0.05, -0.05))
