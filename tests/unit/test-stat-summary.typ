// stat-summary helpers and per-x reduction tests.

#import "../../src/stat/apply.typ": apply-stat
#import "../../src/utils/normal.typ": qnorm
#import "../../src/utils/summaries.typ": (
  _apply-summary, mean, mean-cl-boot, mean-cl-normal, mean-sd, mean-se, median,
  median-hilow, quantile, quantiles,
)

// --- qnorm: Acklam's inverse-normal -----------------------------------------

#assert(calc.abs(qnorm(0.975) - 1.959964) < 1e-6)
#assert(calc.abs(qnorm(0.5)) < 1e-9)
#assert(calc.abs(qnorm(0.025) - (-1.959964)) < 1e-6)
// Tail symmetry: qnorm(1 - p) = -qnorm(p).
#assert(calc.abs(qnorm(0.99) + qnorm(0.01)) < 1e-6)

// --- mean-se on 1..5 -------------------------------------------------------
// mean = 3, sd (n-1) = sqrt(10/4) = sqrt(2.5) ≈ 1.5811
// se = sd / sqrt(5) ≈ 0.7071, so [ymin, ymax] ≈ [2.293, 3.707].

#let r-mse = mean-se((1, 2, 3, 4, 5))
#assert.eq(r-mse.y, 3.0)
#assert(calc.abs(r-mse.ymin - 2.292893) < 1e-4)
#assert(calc.abs(r-mse.ymax - 3.707107) < 1e-4)

// multiplier: 2 doubles the half-width.
#let r-mse2 = mean-se((1, 2, 3, 4, 5), multiplier: 2)
#assert.eq(r-mse2.y, 3.0)
#assert(
  calc.abs((r-mse2.ymax - r-mse2.ymin) - 2 * (r-mse.ymax - r-mse.ymin)) < 1e-9,
)

// --- mean-sd on 1..5 -------------------------------------------------------
// Default multiplier = 1, sd ≈ 1.5811, so half-width ≈ 1.5811.

#let r-sd = mean-sd((1, 2, 3, 4, 5))
#assert.eq(r-sd.y, 3.0)
#assert(calc.abs(r-sd.ymin - (3 - 1.581139)) < 1e-4)
#assert(calc.abs(r-sd.ymax - (3 + 1.581139)) < 1e-4)

// --- mean-cl-normal at 95 % ------------------------------------------------
// Half-width = 1.959964 * se.

#let r-cl = mean-cl-normal((1, 2, 3, 4, 5))
#assert.eq(r-cl.y, 3.0)
#assert(calc.abs(r-cl.ymax - (3 + 1.959964 * 0.707107)) < 1e-4)
#assert(calc.abs(r-cl.ymin - (3 - 1.959964 * 0.707107)) < 1e-4)

// conf = 0.99 must produce a strictly wider band than conf = 0.95.
#let r-cl-99 = mean-cl-normal((1, 2, 3, 4, 5), conf: 0.99)
#assert.eq(r-cl-99.y, 3.0)
#assert((r-cl-99.ymax - r-cl-99.ymin) > (r-cl.ymax - r-cl.ymin))
// Half-width matches z_{0.995} * se with z ≈ 2.5758.
#assert(calc.abs(r-cl-99.ymax - (3 + 2.5758293 * 0.707107)) < 1e-4)

// --- median-hilow with default conf = 0.5 (IQR) ----------------------------
// On 1..9 the type-7 quantiles are Q1=3, Q2=5, Q3=7.

#let r-mhl = median-hilow(range(1, 10))
#assert.eq(r-mhl.y, 5.0)
#assert.eq(r-mhl.ymin, 3.0)
#assert.eq(r-mhl.ymax, 7.0)

// conf = 0.25 -> tail = 0.375 -> ymin at sorted index 3 = 4, ymax at 5 = 6.
#let r-mhl-narrow = median-hilow(range(1, 10), conf: 0.25)
#assert.eq(r-mhl-narrow.ymin, 4.0)
#assert.eq(r-mhl-narrow.ymax, 6.0)

// --- empty input collapses to none ----------------------------------------

#let r-empty = mean-se(())
#assert.eq(r-empty.y, none)
#assert.eq(r-empty.ymin, none)
#assert.eq(r-empty.ymax, none)

#let r-non-numeric = median-hilow(("a", "b"))
#assert.eq(r-non-numeric.y, none)

// --- summarise dispatches by name -----------------------------------------

#let r-dispatch = _apply-summary("mean-se", (1, 2, 3, 4, 5))
#assert.eq(r-dispatch.y, 3.0)

// --- stat-summary: one row per x bucket -----------------------------------

#let df = (
  (g: "a", y: 1),
  (g: "a", y: 2),
  (g: "a", y: 3),
  (g: "a", y: 4),
  (g: "a", y: 5),
  (g: "b", y: 10),
  (g: "b", y: 12),
  (g: "b", y: 14),
)
#let r-stat = apply-stat(
  "summary",
  df,
  (x: "g", y: "y"),
  (fun: "mean-se", "fun-args": (:)),
)
#assert.eq(r-stat.data.len(), 2)
#assert.eq(r-stat.data.at(0).x, "a")
#assert.eq(r-stat.data.at(0).y, 3.0)
#assert(calc.abs(r-stat.data.at(0).ymin - 2.292893) < 1e-4)
#assert(calc.abs(r-stat.data.at(0).ymax - 3.707107) < 1e-4)
#assert.eq(r-stat.data.at(1).x, "b")
#assert.eq(r-stat.data.at(1).y, 12.0)

// Output mapping shape.
#assert.eq(r-stat.mapping.x, "x")
#assert.eq(r-stat.mapping.y, "y")
#assert.eq(r-stat.mapping.ymin, "ymin")
#assert.eq(r-stat.mapping.ymax, "ymax")

// --- stat-summary: numeric x is parsed -------------------------------------

#let df-num = range(0, 5).map(v => (x: 2, y: v))
#let r-stat-num = apply-stat(
  "summary",
  df-num,
  (x: "x", y: "y"),
  (fun: "mean-se", "fun-args": (:)),
)
#assert.eq(r-stat-num.data.at(0).x, 2.0)

// --- stat-summary-bin: per-bin reduction ----------------------------------

#let df-bin = range(0, 10).map(i => (x: i, y: i))
#let r-bin = apply-stat(
  "summary-bin",
  df-bin,
  (x: "x", y: "y"),
  (fun: "mean-se", bins: 2, binwidth: none, "fun-args": (:)),
)
#assert.eq(r-bin.data.len(), 2)
// First bin holds 0..4 with mean 2; second bin holds 5..9 with mean 7.
#assert.eq(r-bin.data.at(0).y, 2.0)
#assert.eq(r-bin.data.at(1).y, 7.0)

// --- mean / median / quantile / quantiles helpers -------------------------

#let r-mean = mean((1, 2, 3, 4, 5))
#assert.eq(r-mean.y, 3.0)
#assert.eq(r-mean.ymin, 3.0)
#assert.eq(r-mean.ymax, 3.0)

#let r-median = median((1, 2, 3, 4))
#assert.eq(r-median.y, 2.5)
#assert.eq(r-median.ymin, 2.5)
#assert.eq(r-median.ymax, 2.5)

#let r-q25 = quantile((1, 2, 3, 4), q: 0.25)
#assert.eq(r-q25.y, 1.75)
#assert.eq(r-q25.ymin, 1.75)
#assert.eq(r-q25.ymax, 1.75)

#let r-qs = quantiles(range(1, 10), probs: (0.25, 0.5, 0.75))
#assert.eq(r-qs.ymin, 3.0)
#assert.eq(r-qs.y, 5.0)
#assert.eq(r-qs.ymax, 7.0)

// Empty input collapses for each helper.
#assert.eq(mean(()).y, none)
#assert.eq(median(()).y, none)
#assert.eq(quantile(()).y, none)
#assert.eq(quantiles(()).y, none)

// --- summarise dispatcher: new string names -------------------------------

#assert.eq(_apply-summary("mean", (1, 2, 3)).y, 2.0)
#assert.eq(_apply-summary("median", (1, 2, 3, 4)).y, 2.5)
#assert.eq(
  _apply-summary("quantile", (1, 2, 3, 4), fun-args: (q: 0.25)).y,
  1.75,
)
#let r-qs-disp = _apply-summary(
  "quantiles",
  range(1, 11),
  fun-args: (probs: (0.1, 0.5, 0.9)),
)
#assert.eq(r-qs-disp.y, 5.5)

// --- summarise dispatcher: callable form ----------------------------------

#let r-fn = _apply-summary(v => (y: 0, ymin: -1, ymax: 1), (1, 2, 3))
#assert.eq(r-fn.y, 0)
#assert.eq(r-fn.ymin, -1)
#assert.eq(r-fn.ymax, 1)

// Callable consumes a fun-arg passed via the dispatcher.
#let r-fn-args = _apply-summary(
  (v, k: 1) => (y: v.sum() * k, ymin: 0, ymax: 0),
  (1, 2, 3),
  fun-args: (k: 2),
)
#assert.eq(r-fn-args.y, 12)

// --- stat-summary: axis = "y" keeps today's per-x bucket shape -------------

#let r-y = apply-stat(
  "summary",
  df,
  (x: "g", y: "y"),
  (fun: "mean-se", "fun-args": (:), axis: "y"),
)
#assert.eq(r-y.data.len(), 2)
#assert("xmin" not in r-y.data.at(0))
#assert("xmax" not in r-y.data.at(0))
#assert.eq(r-y.data.at(0).y, 3.0)

// --- stat-summary: axis = "x" transposes (one row per distinct y) ----------

#let df-x = (
  (g: "a", x: 1),
  (g: "a", x: 2),
  (g: "a", x: 3),
  (g: "b", x: 10),
  (g: "b", x: 11),
)
#let r-x = apply-stat(
  "summary",
  df-x,
  (x: "x", y: "g"),
  (fun: "mean-se", "fun-args": (:), axis: "x"),
)
#assert.eq(r-x.data.len(), 2)
#assert.eq(r-x.data.at(0).y, "a")
#assert.eq(r-x.data.at(0).x, 2.0)
#assert("xmin" in r-x.data.at(0))
#assert("xmax" in r-x.data.at(0))
#assert.eq(r-x.data.at(1).y, "b")
#assert.eq(r-x.data.at(1).x, 10.5)

// --- stat-summary: axis = "both" with discrete x emits degenerate xband ----

#let r-both = apply-stat(
  "summary",
  df,
  (x: "g", y: "y"),
  (fun: "mean-se", "fun-args": (:), axis: "both"),
)
// Discrete x ("a", "b") → no xmin/xmax; bucket path runs but parsed-x is none.
#assert("xmin" not in r-both.data.at(0))
#assert("xmax" not in r-both.data.at(0))
#assert.eq(r-both.data.at(0).y, 3.0)

// Numeric discrete x → degenerate xmin == xmax == parsed-x.
#let df-num-x = (
  (x: 1, y: 1),
  (x: 1, y: 2),
  (x: 1, y: 3),
  (x: 2, y: 10),
  (x: 2, y: 11),
)
#let r-both-num = apply-stat(
  "summary",
  df-num-x,
  (x: "x", y: "y"),
  (fun: "mean-se", "fun-args": (:), axis: "both"),
)
#assert.eq(r-both-num.data.at(0).x, 1.0)
#assert.eq(r-both-num.data.at(0).xmin, 1.0)
#assert.eq(r-both-num.data.at(0).xmax, 1.0)
#assert.eq(r-both-num.data.at(1).x, 2.0)
#assert.eq(r-both-num.data.at(1).xmin, 2.0)

// --- stat-summary: penguins regression (grouping + continuous x) -----------

#let df-pen = (
  (sp: "a", fl: 180.0, bm: 3500.0),
  (sp: "a", fl: 185.0, bm: 3700.0),
  (sp: "a", fl: 190.0, bm: 3900.0),
)
#let r-pen = apply-stat(
  "summary",
  df-pen,
  (x: "fl", y: "bm", colour: "sp"),
  (fun: "mean-se", "fun-args": (:), axis: "both"),
)
// Grouping + continuous x → bivariate collapse: a single row carrying both
// axes' uncertainty (penguins use case).
#assert.eq(r-pen.data.len(), 1)
#assert("xmin" in r-pen.data.at(0))
#assert("xmax" in r-pen.data.at(0))
#assert("ymin" in r-pen.data.at(0))
#assert("ymax" in r-pen.data.at(0))
#assert.eq(r-pen.data.at(0).x, 185.0)
#assert.eq(r-pen.data.at(0).y, 3700.0)
#assert.eq(r-pen.mapping.colour, "sp")

// label aesthetic is preserved through the bivariate-collapse path.
#let r-pen-label = apply-stat(
  "summary",
  df-pen,
  (x: "fl", y: "bm", colour: "sp", label: "sp"),
  (fun: "mean", "fun-args": (:), axis: "both"),
)
#assert.eq(r-pen-label.data.len(), 1)
#assert.eq(r-pen-label.data.at(0).x, 185.0)
#assert.eq(r-pen-label.data.at(0).y, 3700.0)
#assert.eq(r-pen-label.mapping.label, "sp")

// label is preserved through the per-x bucket path (axis = "y").
#let r-label-bucket = apply-stat(
  "summary",
  df,
  (x: "g", y: "y", label: "g"),
  (fun: "mean", "fun-args": (:), axis: "y"),
)
#assert.eq(r-label-bucket.mapping.at("label", default: none), "g")

// label is preserved through the axis = "x" transposed path.
#let r-label-x = apply-stat(
  "summary",
  df-x,
  (x: "x", y: "g", label: "g"),
  (fun: "mean", "fun-args": (:), axis: "x"),
)
#assert.eq(r-label-x.mapping.at("label", default: none), "g")

// --- stat-summary: callable as fun ----------------------------------------

#let r-callable = apply-stat(
  "summary",
  df,
  (x: "g", y: "y"),
  (
    fun: (vs, ..args) => (y: vs.sum(), ymin: 0, ymax: 0),
    "fun-args": (:),
    axis: "y",
  ),
)
#assert.eq(r-callable.data.at(0).y, 15)
#assert.eq(r-callable.data.at(1).y, 36)

// --- weighted summary helpers ---------------------------------------------
// Reference values from R for x = (1, 2, 3, 4, 5), w = (1, 2, 3, 2, 1):
//   m  <- weighted.mean(x, w)                                  # 3
//   sd <- sqrt(sum(w*(x-m)^2) / (sum(w) * (n-1)/n))            # 1.2909944
//   se <- sd / sqrt(sum(w))                                    # 0.4303315
// Gribouille uses the frequency-weight Bessel correction
// (divisor `total * (n-1) / n`); see src/utils/summaries.typ:73-87.

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol

#let w-vals = (1, 2, 3, 4, 5)
#let w-w = (1, 2, 3, 2, 1)

#let r-w-mean = mean(w-vals, weights: w-w)
#assert.eq(r-w-mean.y, 3.0)
#assert.eq(r-w-mean.ymin, r-w-mean.y)
#assert.eq(r-w-mean.ymax, r-w-mean.y)

#let r-w-se = mean-se(w-vals, weights: w-w)
#assert.eq(r-w-se.y, 3.0)
#assert(close(r-w-se.ymin, 2.569668517088065))
#assert(close(r-w-se.ymax, 3.430331482911935))

#let r-w-sd = mean-sd(w-vals, weights: w-w)
#assert.eq(r-w-sd.y, 3.0)
#assert(close(r-w-sd.ymin, 1.709005551264194))
#assert(close(r-w-sd.ymax, 4.290994448735806))

// z_{0.975} = qnorm(0.975) ~= 1.959964; band = m +/- z * se.
#let r-w-cl = mean-cl-normal(w-vals, weights: w-w)
#assert.eq(r-w-cl.y, 3.0)
#assert(close(r-w-cl.ymin, 2.156565792078894, tol: 1e-6))
#assert(close(r-w-cl.ymax, 3.843434207921106, tol: 1e-6))

// All-zero weight collapses to the empty summary.
#assert.eq(mean(w-vals, weights: (0, 0, 0, 0, 0)).y, none)
#assert.eq(mean-se(w-vals, weights: (0, 0, 0, 0, 0)).y, none)

// Unit weights match the unweighted helper exactly.
#let r-w-unit = mean-se(w-vals, weights: (1, 1, 1, 1, 1))
#assert(close(r-w-unit.ymin, r-mse.ymin, tol: 1e-12))
#assert(close(r-w-unit.ymax, r-mse.ymax, tol: 1e-12))

// --- summarise dispatcher: weights forwarded -------------------------------

#let r-w-disp-se = _apply-summary("mean-se", w-vals, weights: w-w)
#assert.eq(r-w-disp-se.ymin, r-w-se.ymin)
#assert.eq(r-w-disp-se.ymax, r-w-se.ymax)

#let r-w-disp-sd = _apply-summary("mean-sd", w-vals, weights: w-w)
#assert.eq(r-w-disp-sd.ymin, r-w-sd.ymin)
#assert.eq(r-w-disp-sd.ymax, r-w-sd.ymax)

#let r-w-disp-cl = _apply-summary("mean-cl-normal", w-vals, weights: w-w)
#assert.eq(r-w-disp-cl.ymin, r-w-cl.ymin)
#assert.eq(r-w-disp-cl.ymax, r-w-cl.ymax)

// --- mean-cl-boot self-consistency ----------------------------------------
// Bootstrap percentiles cannot be derived from R because the resampler is a
// deterministic sin-noise sequence specific to Gribouille
// (src/utils/summaries.typ:422-425). Bounds below are pinned to the resampler
// output for the listed seed/n-boot/conf; any change to `_rand01` or the
// resampling loop must be reflected here intentionally.

#let boot-vals = (2, 3, 4, 5, 6, 7)
#let r-boot-95 = mean-cl-boot(boot-vals, conf: 0.95, n-boot: 200, seed: 42)
#assert.eq(r-boot-95.y, 4.5)
#assert.eq(r-boot-95.ymin, 19.0 / 6.0)
#assert.eq(r-boot-95.ymax, 35.0 / 6.0)

#let r-boot-50 = mean-cl-boot(boot-vals, conf: 0.5, n-boot: 200, seed: 42)
#assert.eq(r-boot-50.y, 4.5)
#assert.eq(r-boot-50.ymin, 4.0)
#assert.eq(r-boot-50.ymax, 4.875)
// Tighter conf -> narrower band.
#assert((r-boot-50.ymax - r-boot-50.ymin) < (r-boot-95.ymax - r-boot-95.ymin))

// Idempotence: identical seed and inputs reproduce identical bounds.
#let r-boot-95-bis = mean-cl-boot(boot-vals, conf: 0.95, n-boot: 200, seed: 42)
#assert.eq(r-boot-95.ymin, r-boot-95-bis.ymin)
#assert.eq(r-boot-95.ymax, r-boot-95-bis.ymax)

// n=1 collapses to a degenerate triple.
#let r-boot-one = mean-cl-boot((7,))
#assert.eq(r-boot-one.y, 7.0)
#assert.eq(r-boot-one.ymin, 7.0)
#assert.eq(r-boot-one.ymax, 7.0)

Stat summary tests passed.
