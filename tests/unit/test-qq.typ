// Q-Q statistic and helper tests.

#import "../../src/utils/normal.typ": qnorm, theoretical-quantile
#import "../../src/stat/apply.typ": apply-stat, resolve-stat-spec
#import "../../src/geom/qq.typ": geom-qq
#import "../../src/geom/qq-line.typ": geom-qq-line

// --- qnorm: classic 95 % quantile -----------------------------------------
// Acklam's approximation matches the standard z to about 1.15e-9.
#assert(calc.abs(qnorm(0.975) - 1.959964) < 1e-5)
#assert(calc.abs(qnorm(0.025) + 1.959964) < 1e-5)
#assert(calc.abs(qnorm(0.5)) < 1e-9)
#assert(calc.abs(qnorm(0.75) - 0.6744898) < 1e-5)

// --- stat-qq: 5 sorted rows with theoretical at (i + 0.5) / n -------------

#let df = (5, 3, 1, 4, 2).map(v => (v: v))
#let r = apply-stat("qq", df, (y: "v"), (:))

#assert.eq(r.data.len(), 5)
#assert.eq(r.mapping.x, "theoretical")
#assert.eq(r.mapping.y, "sample")

// Sample is sorted ascending.
#let samples = r.data.map(row => row.sample)
#assert.eq(samples, (1.0, 2.0, 3.0, 4.0, 5.0))

// Theoretical quantiles match qnorm at the plotting positions.
#let expected-ps = (0.1, 0.3, 0.5, 0.7, 0.9)
#for (i, p) in expected-ps.enumerate() {
  assert(calc.abs(r.data.at(i).theoretical - qnorm(p)) < 1e-9)
}

// --- stat-qq: falls back to y when sample is not mapped -------------------

#let r-y = apply-stat("qq", df, (y: "v"), (:))
#assert.eq(r-y.data.len(), 5)

// --- stat-qq: drops non-numeric and none values ---------------------------

#let df-mixed = (
  (v: 1),
  (v: none),
  (v: "oops"),
  (v: 2),
)
#let r-mixed = apply-stat("qq", df-mixed, (y: "v"), (:))
#assert.eq(r-mixed.data.len(), 2)

// --- stat-qq-line: two endpoints with intercept zero on (1..5) ------------
// On (1..5) sorted, q1 = 2, q3 = 4, so slope = 2 / (qnorm(0.75) - qnorm(0.25))
// and intercept = 2 - slope * qnorm(0.25) = 3.

#let r-line = apply-stat("qq-line", df, (y: "v"), (:))
#assert.eq(r-line.data.len(), 2)
#assert.eq(r-line.mapping.x, "theoretical")
#assert.eq(r-line.mapping.y, "sample")

#let slope = 2.0 / (qnorm(0.75) - qnorm(0.25))
#let intercept = 2.0 - slope * qnorm(0.25)
#assert(calc.abs(intercept - 3.0) < 1e-9)

#let t-lo = qnorm(0.5 / 5)
#let t-hi = qnorm(4.5 / 5)
#assert(calc.abs(r-line.data.at(0).theoretical - t-lo) < 1e-9)
#assert(calc.abs(r-line.data.at(1).theoretical - t-hi) < 1e-9)
#assert(calc.abs(r-line.data.at(0).sample - (intercept + slope * t-lo)) < 1e-9)
#assert(calc.abs(r-line.data.at(1).sample - (intercept + slope * t-hi)) < 1e-9)

// --- theoretical-quantile: dispatches per distribution -------------------

#assert(calc.abs(theoretical-quantile("stat-qq", 0.5, "normal")) < 1e-9)
#assert(
  calc.abs(theoretical-quantile("stat-qq", 0.25, "uniform") - 0.25) < 1e-9,
)
#assert(
  calc.abs(theoretical-quantile("stat-qq", 0.5, "exponential") - calc.ln(2))
    < 1e-9,
)

// --- stat-qq: uniform distribution uses p directly -----------------------

#let r-uniform = apply-stat(
  "qq",
  df,
  (y: "v"),
  (distribution: "uniform"),
)
#assert.eq(r-uniform.data.len(), 5)
#for (i, p) in expected-ps.enumerate() {
  assert(calc.abs(r-uniform.data.at(i).theoretical - p) < 1e-9)
}

// --- stat-qq: exponential distribution uses -ln(1 - p) -------------------

#let r-exp = apply-stat(
  "qq",
  df,
  (y: "v"),
  (distribution: "exponential"),
)
#assert.eq(r-exp.data.len(), 5)
#for (i, p) in expected-ps.enumerate() {
  assert(calc.abs(r-exp.data.at(i).theoretical - (-calc.ln(1 - p))) < 1e-9)
}

// --- stat-qq-line: exponential matches the IQR fit -----------------------

#let r-line-exp = apply-stat(
  "qq-line",
  df,
  (y: "v"),
  (distribution: "exponential"),
)
#assert.eq(r-line-exp.data.len(), 2)
#let z1-exp = -calc.ln(0.75)
#let z3-exp = -calc.ln(0.25)
#let slope-exp = 2.0 / (z3-exp - z1-exp)
#let intercept-exp = 2.0 - slope-exp * z1-exp
#let t-lo-exp = -calc.ln(1 - 0.5 / 5)
#let t-hi-exp = -calc.ln(1 - 4.5 / 5)
#assert(calc.abs(r-line-exp.data.at(0).theoretical - t-lo-exp) < 1e-9)
#assert(calc.abs(r-line-exp.data.at(1).theoretical - t-hi-exp) < 1e-9)
#assert(
  calc.abs(
    r-line-exp.data.at(0).sample - (intercept-exp + slope-exp * t-lo-exp),
  )
    < 1e-9,
)

// --- resolve-stat-spec: string stat inherits the geom's own params --------
// Regression: geom-qq stores `distribution` in its params and dispatches the
// stat by string name, so the resolver must forward those params to the stat
// rather than dropping them for the constructor defaults.

#let qq-layer = geom-qq(distribution: "uniform")
#let qq-resolved = resolve-stat-spec(qq-layer.stat, qq-layer.params)
#assert.eq(qq-resolved.name, "qq")
#assert.eq(qq-resolved.params.distribution, "uniform")

#let qq-line-layer = geom-qq-line(distribution: "exponential")
#let qq-line-resolved = resolve-stat-spec(
  qq-line-layer.stat,
  qq-line-layer.params,
)
#assert.eq(qq-line-resolved.name, "qq-line")
#assert.eq(qq-line-resolved.params.distribution, "exponential")

// --- resolve-stat-spec: stat-*() dict carries its own name and params ------

#let dict-resolved = resolve-stat-spec(
  (kind: "stat", name: "boxplot", params: (coefficient: 1.0)),
  (width: 0.6),
)
#assert.eq(dict-resolved.name, "boxplot")
#assert.eq(dict-resolved.params.coefficient, 1.0)

QQ tests passed.
