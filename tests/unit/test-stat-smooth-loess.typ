// stat-smooth(method: "loess"): tricube-weighted local polynomial fits.

#import "../../src/stat/apply.typ": apply-stat, stat-default-params
#import "../../src/stat/smooth.typ": stat-smooth

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol
#let params(..over) = stat-default-params("smooth") + over.named()

// --- degree-2 fit, default span, 95% band ------------------------------------
// Exact references computed externally with the same construction: q nearest
// points by |x - x0| with q = floor(span * n), tricube weights, centred
// weighted polynomial solved by elimination, residual variance from the
// weighted RSS over n - trace(L) degrees of freedom, normal-quantile band.
// Sample: x = i * 0.5, y = sin(i * 0.5) + 0.1 * i for i in 0..19.

#let d = range(0, 20).map(i => (
  x: i * 0.5,
  y: calc.sin(i * 0.5) + 0.1 * i,
))
#let r = apply-stat("smooth", d, (x: "x", y: "y"), params(method: "loess"))

#assert.eq(r.data.len(), 81)
#assert.eq(r.mapping.x, "x")
#assert.eq(r.mapping.y, "y")
#assert.eq(r.mapping.ymin, "ymin")
#assert.eq(r.mapping.ymax, "ymax")

#let expected = (
  (0, 0.0, 0.351444281707033, -0.047892314786545, 0.750780878200610),
  (20, 2.375, 0.873000491121457, 0.650110834302263, 1.095890147940650),
  (40, 4.75, 0.118195727691900, -0.116507032449374, 0.352898487833175),
  (60, 7.125, 1.870335923513487, 1.647446266694294, 2.093225580332680),
  (80, 9.5, 2.149130864859987, 1.749794268366409, 2.548467461353564),
)
#for (i, x, y, ymin, ymax) in expected {
  let row = r.data.at(i)
  assert(close(row.x, x))
  assert(close(row.y, y, tol: 1e-9))
  assert(close(row.ymin, ymin, tol: 1e-6))
  assert(close(row.ymax, ymax, tol: 1e-6))
}

// --- degree 1, tighter span ---------------------------------------------------

#let r1 = apply-stat(
  "smooth",
  d,
  (x: "x", y: "y"),
  params(method: "loess", span: 0.5, degree: 1),
)
#assert(close(r1.data.at(40).y, 0.270841031477263, tol: 1e-9))
#assert(close(r1.data.at(40).ymin, 0.006519437352858, tol: 1e-6))

// --- weights enter the local fits and the residual variance -------------------
// Double weight on even indices; references use the weighted RSS.

#let dw = range(0, 20).map(i => (
  x: i * 0.5,
  y: calc.sin(i * 0.5) + 0.1 * i,
  w: if calc.rem(i, 2) == 0 { 2 } else { 1 },
))
#let rw = apply-stat(
  "smooth",
  dw,
  (x: "x", y: "y", weight: "w"),
  params(method: "loess"),
)
#assert(close(rw.data.at(0).y, 0.303375481521178, tol: 1e-9))
#assert(close(rw.data.at(40).y, 0.118159468957371, tol: 1e-9))
#assert(close(rw.data.at(40).ymax, 0.421602078997395, tol: 1e-6))
#assert(close(rw.data.at(80).ymin, 1.691743389979496, tol: 1e-6))

// --- se: false collapses the band ---------------------------------------------

#let rn = apply-stat(
  "smooth",
  d,
  (x: "x", y: "y"),
  params(method: "loess", se: false),
)
#assert.eq(rn.data.at(40).ymin, rn.data.at(40).y)
#assert.eq(rn.data.at(40).ymax, rn.data.at(40).y)

// --- grouping: one loess curve per colour level --------------------------------

#let dg = ()
#for grp in ("a", "b") {
  for i in range(0, 12) {
    dg.push((
      x: i,
      y: calc.sin(i * 0.5) + (if grp == "b" { 3 } else { 0 }),
      grp: grp,
    ))
  }
}
#let rg = apply-stat(
  "smooth",
  dg,
  (x: "x", y: "y", colour: "grp"),
  params(method: "loess"),
)
#assert.eq(rg.data.len(), 162)
#assert.eq(rg.data.filter(row => row.grp == "a").len(), 81)

// --- edge cases -----------------------------------------------------------------

// Fewer points than degree + 1 emits no rows for that group.
#let tiny = ((x: 1, y: 1), (x: 2, y: 2))
#assert.eq(
  apply-stat("smooth", tiny, (x: "x", y: "y"), params(method: "loess")).data,
  (),
)

// Tied x values fall back to the weighted local mean instead of failing.
#let tied = ((x: 1, y: 1), (x: 1, y: 2), (x: 1, y: 3), (x: 1, y: 6))
#let rt = apply-stat(
  "smooth",
  tied,
  (x: "x", y: "y"),
  params(method: "loess"),
)
#assert.eq(rt.data.len(), 81)
#assert(close(rt.data.at(0).y, 3.0))

// Constructor carries its params.
#assert.eq(
  stat-smooth(method: "loess", span: 0.4, degree: 1).params,
  (method: "loess", se: true, level: 0.95, span: 0.4, degree: 1),
)

stat-smooth loess tests passed.
