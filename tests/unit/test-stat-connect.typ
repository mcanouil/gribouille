#import "../../src/stat/connect.typ": apply, stat-connect
#import "../../src/stat/info.typ": stat-info, stat-names

#let s = stat-connect()
#assert.eq(s.kind, "stat")
#assert.eq(s.name, "connect")
#assert.eq(s.params.connection, "hv")

#let d = (
  (x: 0, y: 0),
  (x: 1, y: 2),
  (x: 2, y: 1),
)
#let mapping = (x: "x", y: "y")

// hv: each gap inserts (x_{i+1}, y_i). 3 input -> 5 output.
#let r-hv = apply(d, mapping, params: (connection: "hv"))
#assert.eq(r-hv.data.len(), 5)
#assert.eq(r-hv.data.at(0), (x: 0, y: 0))
#assert.eq(r-hv.data.at(1), (x: 1, y: 0))
#assert.eq(r-hv.data.at(2), (x: 1, y: 2))
#assert.eq(r-hv.data.at(3), (x: 2, y: 2))
#assert.eq(r-hv.data.at(4), (x: 2, y: 1))

// vh: each gap inserts (x_i, y_{i+1}). 3 -> 5.
#let r-vh = apply(d, mapping, params: (connection: "vh"))
#assert.eq(r-vh.data.len(), 5)
#assert.eq(r-vh.data.at(1), (x: 0, y: 2))
#assert.eq(r-vh.data.at(3), (x: 1, y: 1))

// mid: each gap inserts (mid, y_i) and (mid, y_{i+1}). 3 -> 7.
#let r-mid = apply(d, mapping, params: (connection: "mid"))
#assert.eq(r-mid.data.len(), 7)
#assert.eq(r-mid.data.at(1), (x: 0.5, y: 0))
#assert.eq(r-mid.data.at(2), (x: 0.5, y: 2))
#assert.eq(r-mid.data.at(4), (x: 1.5, y: 2))
#assert.eq(r-mid.data.at(5), (x: 1.5, y: 1))

// linear: pass-through (sorted). 3 -> 3.
#let r-linear = apply(d, mapping, params: (connection: "linear"))
#assert.eq(r-linear.data.len(), 3)
#assert.eq(r-linear.data, d)

// Sorts by x before expansion.
#let unsorted = ((x: 2, y: 1), (x: 0, y: 0), (x: 1, y: 2))
#let r-sorted = apply(unsorted, mapping, params: (connection: "hv"))
#assert.eq(r-sorted.data.first().x, 0)
#assert.eq(r-sorted.data.last().x, 2)

// String-typed numerics sort numerically, not lexicographically.
#let strs = ((x: "10", y: 1), (x: "2", y: 2))
#let r-s = apply(strs, mapping, params: (connection: "linear"))
#assert.eq(r-s.data.first().x, "2")
#assert.eq(r-s.data.last().x, "10")

// Other columns inherited from preceding row.
#let coloured = (
  (x: 0, y: 0, grp: "a"),
  (x: 1, y: 2, grp: "a"),
)
#let r-c = apply(coloured, mapping, params: (connection: "hv"))
#assert.eq(r-c.data.at(1).grp, "a")

// Single row passes through.
#let r-1 = apply(((x: 0, y: 0),), mapping, params: (connection: "hv"))
#assert.eq(r-1.data.len(), 1)

#assert.eq(stat-info("connect").outputs, ("x", "y"))
#assert("connect" in stat-names())

// --- sigmoid connection -------------------------------------------------------
// Exact logistic reference on the unit gap (0, 0) -> (1, 1), smooth = 8,
// n = 3 interior points at t = 0.25, 0.5, 0.75, computed externally with
// eased(t) = (sigma(8 * (2t - 1)) - sigma(-8)) / (sigma(8) - sigma(-8)).

#let close(a, b, tol: 1e-12) = calc.abs(a - b) < tol

#let unit = ((x: 0, y: 0), (x: 1, y: 1))
#let r-sig = apply(
  unit,
  mapping,
  params: (connection: "sigmoid", smooth: 8, n: 3),
)
#assert.eq(r-sig.data.len(), 5)
#assert.eq(r-sig.data.first(), (x: 0, y: 0))
#assert.eq(r-sig.data.last(), (x: 1, y: 1))
#assert(close(r-sig.data.at(1).x, 0.25))
#assert(close(r-sig.data.at(1).y, 0.017662706213291114))
#assert(close(r-sig.data.at(2).y, 0.5))
#assert(close(r-sig.data.at(3).y, 0.9823372937867088))

// Rescale pins the curve to arbitrary endpoints: (1, 4) -> (3, 2) with
// smooth = 4, n = 2 at t = 1/3, 2/3; eased = 0.1977353359008273 and
// 0.8022646640991726, so y = 4 - 2 * eased.
#let r-sig2 = apply(
  ((x: 1, y: 4), (x: 3, y: 2)),
  mapping,
  params: (connection: "sigmoid", smooth: 4, n: 2),
)
#assert.eq(r-sig2.data.len(), 4)
#assert(close(r-sig2.data.at(1).x, 1 + 2 / 3))
#assert(close(r-sig2.data.at(1).y, 4 - 2 * 0.1977353359008273))
#assert(close(r-sig2.data.at(2).x, 1 + 4 / 3))
#assert(close(r-sig2.data.at(2).y, 4 - 2 * 0.8022646640991726))

// Multi-gap: each gap gains n interior vertices.
#let r-sig3 = apply(
  ((x: 0, y: 0), (x: 1, y: 1), (x: 2, y: 0)),
  mapping,
  params: (connection: "sigmoid", smooth: 8, n: 4),
)
#assert.eq(r-sig3.data.len(), 3 + 2 * 4)

// Constructor carries and validates the sigmoid params.
#let spec = stat-connect(connection: "sigmoid", smooth: 6, n: 10)
#assert.eq(spec.params.connection, "sigmoid")
#assert.eq(spec.params.smooth, 6)
#assert.eq(spec.params.n, 10)
