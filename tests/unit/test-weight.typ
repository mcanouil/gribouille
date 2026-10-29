// Weight aesthetic threading through stats: count, bin, ecdf, smooth, summary.

#import "../../src/stat/apply.typ": apply-stat
#import "../../src/utils/summaries.typ": mean, mean-cl-normal, mean-sd, mean-se

#let assert-close(a, b, tol: 1e-9) = {
  assert(
    calc.abs(a - b) < tol,
    message: "expected " + repr(a) + " ~= " + repr(b),
  )
}

// stat-count honours per-row weights.
#let df-count = (
  (grp: "a", w: 2),
  (grp: "b", w: 3),
  (grp: "a", w: 1),
)
#let r-count = apply-stat(
  "count",
  df-count,
  (x: "grp", weight: "w"),
  (:),
)
#assert.eq(r-count.data.at(0)._count, 3)
#assert.eq(r-count.data.at(1)._count, 3)

// stat-sum honours per-row weights.
#let df-sum = (
  (x: 1, y: 1, w: 5),
  (x: 1, y: 1, w: 3),
  (x: 2, y: 2, w: 1),
)
#let r-sum = apply-stat(
  "sum",
  df-sum,
  (x: "x", y: "y", weight: "w"),
  (:),
)
#assert.eq(r-sum.data.at(0)._n, 8)
#assert.eq(r-sum.data.at(1)._n, 1)

// stat-bin sums weights per bin instead of counting rows.
#let df-bin = (
  (x: 0.1, w: 4),
  (x: 0.2, w: 1),
  (x: 0.9, w: 2),
)
#let r-bin = apply-stat(
  "bin",
  df-bin,
  (x: "x", weight: "w"),
  (bins: 2),
)
#assert.eq(r-bin.data.len(), 2)
#assert.eq(r-bin.data.at(0).y, 5)
#assert.eq(r-bin.data.at(1).y, 2)

// stat-ecdf uses weights as the cumulative mass; total weights normalise.
#let df-ecdf = (
  (x: 1, w: 3),
  (x: 2, w: 1),
  (x: 3, w: 2),
)
#let r-ecdf = apply-stat(
  "ecdf",
  df-ecdf,
  (x: "x", weight: "w"),
  (:),
)
#assert-close(r-ecdf.data.at(0).y, 3 / 6)
#assert-close(r-ecdf.data.at(1).y, 4 / 6)
#assert-close(r-ecdf.data.at(2).y, 6 / 6)

// Weighted mean: weights of (1, 2, 1) on values (10, 20, 30) collapse to a
// weighted mean of 80/4 = 20 (vs unweighted (10+20+30)/3 = 20 — equal here,
// so flip a value to disambiguate).
#assert.eq(mean((1, 2, 3), weights: (1, 1, 1)).y, 2)
#assert.eq(mean((1, 2, 3), weights: (3, 1, 0)).y, 1.25)

// Weighted mean-se with all-equal weights matches the unweighted call.
#let s-equal = mean-se((2, 4, 6, 8), weights: (1, 1, 1, 1))
#let s-plain = mean-se((2, 4, 6, 8))
#assert-close(s-equal.y, s-plain.y)
#assert-close(s-equal.ymin, s-plain.ymin)
#assert-close(s-equal.ymax, s-plain.ymax)

// Weighted stat-summary delegates to the weighted helper.
#let df-summary = (
  (g: "a", y: 1, w: 1),
  (g: "a", y: 9, w: 1),
  (g: "b", y: 0, w: 1),
  (g: "b", y: 0, w: 9),
)
#let r-summary = apply-stat(
  "summary",
  df-summary,
  (x: "g", y: "y", weight: "w"),
  (fun: "mean", "fun-args": (:)),
)
// Bucket "a" weighted-mean = (1*1 + 9*1) / 2 = 5
// Bucket "b" weighted-mean = (0*1 + 0*9) / 10 = 0
#assert-close(r-summary.data.at(0).y, 5)
#assert-close(r-summary.data.at(1).y, 0)

// A weight that is not a number drops its row, like a non-numeric value.
#assert.eq(mean((1, 5, 3), weights: (1, "NA", 1)).y, 2.0)
#assert.eq(mean((1, 5, 3), weights: (1, "x", "1")).y, 2.0)
#assert.eq(mean((1, 5), weights: (1, float.nan)).y, 1.0)
#let r-na = apply-stat(
  "count",
  ((x: "a", w: 2), (x: "a", w: "NA"), (x: "b", w: 3)),
  (x: "x", weight: "w"),
  (:),
)
#assert.eq(r-na.data.map(row => row._count), (2, 3))

Weight aesthetic stat-routing tests passed.
