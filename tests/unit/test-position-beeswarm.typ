// position-beeswarm: deterministic density-shaped offsets.

#import "../../src/position/apply.typ": apply-position
#import "../../src/position/beeswarm.typ": position-beeswarm

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol

// --- exact offsets on one bucket ----------------------------------------------
// Externally computed references: y = (1, 1.1, 1.2, 2, 2.05, 2.1, 2.15, 3),
// bw.nrd0 = 0.403968960822695, Gaussian KDE evaluated at each point,
// offset = width · (2·vanDerCorput(rank + 1) − 1) · density / peak with
// rank the position in y order and width 0.4.

#let ys = (1.0, 1.1, 1.2, 2.0, 2.05, 2.1, 2.15, 3.0)
#let d = ys.map(v => (x: 1, y: v))
#let r = apply-position(
  "beeswarm",
  d,
  (x: "x", y: "y"),
  params: position-beeswarm().params,
)

#assert.eq(r.data.len(), 8)
#let expected = (
  0.0,
  -0.149958202230281,
  0.153939017871131,
  -0.299247636845191,
  0.100000000000000,
  -0.099268291438924,
  0.292573513479309,
  -0.107938450461015,
)
#for (i, e) in expected.enumerate() {
  assert(close(r.data.at(i).x, 1 + e))
  assert.eq(r.data.at(i).y, ys.at(i))
}

// Deterministic: a second run gives identical offsets.
#let r2 = apply-position(
  "beeswarm",
  d,
  (x: "x", y: "y"),
  params: position-beeswarm().params,
)
#assert.eq(r.data, r2.data)

// Offsets stay within ±width.
#assert(r.data.all(row => calc.abs(row.x - 1) <= 0.4))

// --- buckets are independent ---------------------------------------------------
// Two x values swarm separately; each bucket's densest point takes the
// widest spread of its own bucket.

#let d2 = ys.map(v => (x: 1, y: v)) + ys.map(v => (x: 2, y: v))
#let rb = apply-position(
  "beeswarm",
  d2,
  (x: "x", y: "y"),
  params: position-beeswarm().params,
)
#for (i, e) in expected.enumerate() {
  assert(close(rb.data.at(i).x, 1 + e))
  assert(close(rb.data.at(i + 8).x, 2 + e))
}

// --- parameters ------------------------------------------------------------------

// width scales the offsets linearly.
#let rw = apply-position(
  "beeswarm",
  d,
  (x: "x", y: "y"),
  params: position-beeswarm(width: 0.2).params,
)
#for (i, e) in expected.enumerate() {
  assert(close(rw.data.at(i).x, 1 + e / 2))
}

// width: 0 leaves the data untouched.
#let r0 = apply-position(
  "beeswarm",
  d,
  (x: "x", y: "y"),
  params: position-beeswarm(width: 0).params,
)
#assert.eq(r0.data, d)

// adjust changes the density estimate, hence the offsets.
#let ra = apply-position(
  "beeswarm",
  d,
  (x: "x", y: "y"),
  params: position-beeswarm(adjust: 2).params,
)
#assert(not close(ra.data.at(3).x, rb.data.at(3).x))

// --- edge cases -------------------------------------------------------------------

// A single point per bucket stays on its spine.
#let r1 = apply-position(
  "beeswarm",
  ((x: 1, y: 5), (x: 2, y: 6)),
  (x: "x", y: "y"),
  params: position-beeswarm().params,
)
#assert.eq(r1.data.at(0).x, 1)
#assert.eq(r1.data.at(1).x, 2)

// Non-numeric x (unforced discrete level) passes through unchanged.
#let rd = apply-position(
  "beeswarm",
  (("a", 1), ("a", 2)).map(((g, v)) => (grp: g, y: v)),
  (x: "grp", y: "y"),
  params: position-beeswarm().params,
)
#assert.eq(rd.data.at(0).grp, "a")

// Empty input passes through.
#assert.eq(
  apply-position(
    "beeswarm",
    (),
    (x: "x", y: "y"),
    params: position-beeswarm().params,
  ).data,
  (),
)

position-beeswarm tests passed.
