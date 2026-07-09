// stat-density: Gaussian kernel density estimate.

#import "../../src/stat/apply.typ": apply-stat, stat-default-params
#import "../../src/stat/density.typ": stat-density

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol
#let params(..over) = stat-default-params("density") + over.named()

// --- fixed bandwidth on a trimmed grid -------------------------------------
// Exact sum-of-Gaussians reference computed externally with
// density(g) = (1 / (n * bw * sqrt(2 * pi))) * sum(exp(-((g - x) / bw)^2 / 2))
// on x = c(1, 2, 3, 4, 5), bw = 1, grid = c(1, 2, 3, 4, 5).

#let d5 = (1, 2, 3, 4, 5).map(v => (x: v))
#let r = apply-stat("density", d5, (x: "x"), params(bw: 1, n: 5, trim: true))

#assert.eq(r.data.len(), 5)
#assert.eq(r.mapping.x, "x")
#assert.eq(r.mapping.y, "y")
#let expected = (
  0.139893930014293,
  0.188261308872969,
  0.198173132493219,
  0.188261308872969,
  0.139893930014293,
)
#for (i, e) in expected.enumerate() {
  assert.eq(r.data.at(i).x, float(i + 1))
  assert(close(r.data.at(i).y, e))
  assert.eq(r.data.at(i)._density, r.data.at(i).y)
}

// Symmetric sample: the curve peaks at the centre and `_scaled` tops at 1.
#assert(close(r.data.at(2)._scaled, 1.0))
#assert(close(r.data.at(0)._count, expected.at(0) * 5))
#assert.eq(r.data.at(0)._n, 5)

// --- Silverman bandwidth (bw.nrd0) on an untrimmed grid --------------------
// Reference from R's bw.nrd0 on x = c(1,2,2,3,4,4,4,5,6,7):
//   bw = 0.9 * min(sd, IQR / 1.34) * n^(-1/5) = 1.059443302298832
// Grid spans min - 3 * bw to max + 3 * bw; densities are the exact
// sum-of-Gaussians values on the eight-point grid.

#let dups = (1, 2, 2, 3, 4, 4, 4, 5, 6, 7).map(v => (x: v))
#let rn = apply-stat("density", dups, (x: "x"), params(n: 8))

#assert.eq(rn.data.len(), 8)
#assert(close(rn.data.first().x, -2.178329906896495))
#assert(close(rn.data.last().x, 10.178329906896495))
#let expected-nrd0 = (
  0.000450138964108,
  0.021327908496690,
  0.114408960340040,
  0.174303669325513,
  0.153641548501033,
  0.083177102985942,
  0.018514119712305,
  0.000434353310816,
)
#for (i, e) in expected-nrd0.enumerate() {
  assert(close(rn.data.at(i).y, e))
}
#assert(close(rn.data.at(3)._scaled, 1.0))

// --- weights ----------------------------------------------------------------
// x = c(0, 10) with weights c(3, 1), bw = 1: the mass near 0 is three times
// the mass near 10 and the midpoint is essentially zero.

#let wdata = ((x: 0, w: 3), (x: 10, w: 1))
#let rw = apply-stat(
  "density",
  wdata,
  (x: "x", weight: "w"),
  params(bw: 1, n: 3, trim: true),
)
#assert.eq(rw.data.len(), 3)
#assert(close(rw.data.at(0).y, 0.299206710301075))
#assert(close(rw.data.at(1).y, 0.000001486719515))
#assert(close(rw.data.at(2).y, 0.099735570100358))

// --- the density integrates to ~1 ------------------------------------------
// Trapezoid rule over the default 512-point untrimmed grid.

#let ri = apply-stat("density", dups, (x: "x"), params())
#assert.eq(ri.data.len(), 512)
#let step = ri.data.at(1).x - ri.data.at(0).x
#let integral = {
  range(511).map(i => (ri.data.at(i).y + ri.data.at(i + 1).y) / 2 * step).sum()
}
#assert(calc.abs(integral - 1) < 1e-3)

// --- adjust widens the kernels ----------------------------------------------
// Doubling the bandwidth flattens the curve: the peak drops.

#let ra = apply-stat("density", dups, (x: "x"), params(adjust: 2, n: 64))
#let peak-default = calc.max(
  ..apply-stat(
    "density",
    dups,
    (x: "x"),
    params(n: 64),
  )
    .data
    .map(p => p.y),
)
#let peak-adjusted = calc.max(..ra.data.map(p => p.y))
#assert(peak-adjusted < peak-default)

// --- edge cases --------------------------------------------------------------

// Empty input and single observations emit no rows (no spread to smooth).
#assert.eq(apply-stat("density", (), (x: "x"), params()).data, ())
#assert.eq(apply-stat("density", ((x: 42),), (x: "x"), params()).data, ())

// Non-numeric x is dropped; the two numeric rows still produce a full grid.
#let mixed = ((x: 1), (x: "no"), (x: 2), (x: none))
#let rmixed = apply-stat("density", mixed, (x: "x"), params(n: 16))
#assert.eq(rmixed.data.len(), 16)

// All-zero weight (no positive mass) emits no rows.
#let zero = (1, 2, 3).map(v => (x: v, w: 0))
#assert.eq(
  apply-stat("density", zero, (x: "x", weight: "w"), params()).data,
  (),
)

// Constructor carries its params.
#assert.eq(
  stat-density(bw: 2, adjust: 0.5, n: 128, trim: true).params,
  (bw: 2, adjust: 0.5, n: 128, trim: true),
)

stat-density tests passed.
