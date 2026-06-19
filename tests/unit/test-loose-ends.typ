// Loose-ends slice: stat-sum, geom-count, geom-errorbarh, stat-function,
// mean-cl-boot.

#import "../../src/stat/apply.typ": apply-stat
#import "../../src/stat/sum.typ": stat-sum
#import "../../src/stat/function.typ": stat-function
#import "../../src/geom/count.typ": geom-count
#import "../../src/geom/errorbarh.typ": geom-errorbarh
#import "../../src/utils/summaries.typ": mean-cl-boot, summarise

// --- stat-sum: counts unique (x, y) pairs ---------------------------------

#let r-sum-meta = stat-sum()
#assert.eq(r-sum-meta.kind, "stat")
#assert.eq(r-sum-meta.name, "sum")

#let df-sum = (
  (x: 1, y: 1),
  (x: 1, y: 1),
  (x: 2, y: 2),
)
#let r-sum = apply-stat("sum", df-sum, (x: "x", y: "y"), (:))

#assert.eq(r-sum.data.len(), 2)
#assert.eq(r-sum.data.at(0).x, 1)
#assert.eq(r-sum.data.at(0).y, 1)
#assert.eq(r-sum.data.at(0)._n, 2)
#assert(calc.abs(r-sum.data.at(0)._prop - 2 / 3) < 1e-9)
#assert.eq(r-sum.data.at(1).x, 2)
#assert.eq(r-sum.data.at(1).y, 2)
#assert.eq(r-sum.data.at(1)._n, 1)
#assert(calc.abs(r-sum.data.at(1)._prop - 1 / 3) < 1e-9)

// Output mapping wires `size` to `_n`.
#assert.eq(r-sum.mapping.x, "x")
#assert.eq(r-sum.mapping.y, "y")
#assert.eq(r-sum.mapping.size, "_n")

// --- geom-count: layer dict shape -----------------------------------------

#let l-count = geom-count()
#assert.eq(l-count.kind, "layer")
#assert.eq(l-count.geom, "point")
#assert.eq(l-count.stat, "sum")

// --- geom-errorbarh: layer dict shape -------------------------------------

#let l-eb = geom-errorbarh(height: 0.4)
#assert.eq(l-eb.kind, "layer")
#assert.eq(l-eb.geom, "errorbarh")
#assert.eq(l-eb.params.height, 0.4)
#assert.eq(l-eb.stat, "identity")

// --- stat-function: samples fun across x-limits --------------------------------

#let r-fn-meta = stat-function(fun: x => x * x, n: 5, x-limits: (0, 4))
#assert.eq(r-fn-meta.kind, "stat")
#assert.eq(r-fn-meta.name, "function")

#let r-fn = apply-stat(
  "function",
  (),
  none,
  (fun: x => x * x, n: 5, x-limits: (0, 4), args: (:)),
)
#assert.eq(r-fn.data.len(), 5)
#assert.eq(r-fn.data.at(0).x, 0.0)
#assert.eq(r-fn.data.at(0).y, 0.0)
#assert.eq(r-fn.data.at(4).x, 4.0)
#assert.eq(r-fn.data.at(4).y, 16.0)
#assert.eq(r-fn.mapping.x, "x")
#assert.eq(r-fn.mapping.y, "y")

// x-limits: none falls back to data x range.
#let r-fn-data = apply-stat(
  "function",
  ((x: 0, y: 0), (x: 2, y: 0)),
  (x: "x", y: "y"),
  (fun: x => x + 1, n: 3, x-limits: none, args: (:)),
)
#assert.eq(r-fn-data.data.len(), 3)
#assert.eq(r-fn-data.data.at(0).x, 0.0)
#assert.eq(r-fn-data.data.at(0).y, 1.0)
#assert.eq(r-fn-data.data.at(2).x, 2.0)
#assert.eq(r-fn-data.data.at(2).y, 3.0)

// --- mean-cl-boot: deterministic, brackets the sample mean -----------------

#let xs = (1.0, 2.0, 3.0, 4.0, 5.0)
#let r-boot-a = mean-cl-boot(xs, conf: 0.95, n-boot: 200, seed: 42)
#let r-boot-b = mean-cl-boot(xs, conf: 0.95, n-boot: 200, seed: 42)

// Determinism: identical seed/inputs give identical bounds.
#assert.eq(r-boot-a.y, r-boot-b.y)
#assert.eq(r-boot-a.ymin, r-boot-b.ymin)
#assert.eq(r-boot-a.ymax, r-boot-b.ymax)

// Central value is the sample mean.
#assert.eq(r-boot-a.y, 3.0)

// CI brackets the mean.
#assert(r-boot-a.ymin <= 3.0)
#assert(r-boot-a.ymax >= 3.0)

// Wider conf => wider band.
#let r-boot-99 = mean-cl-boot(xs, conf: 0.99, n-boot: 200, seed: 42)
#assert((r-boot-99.ymax - r-boot-99.ymin) >= (r-boot-a.ymax - r-boot-a.ymin))

// summarise() dispatches by name.
#let r-disp-kebab = summarise(
  "mean-cl-boot",
  xs,
  fun-args: (conf: 0.95, n-boot: 200, seed: 42),
)
#assert.eq(r-disp-kebab.y, r-boot-a.y)
#assert.eq(r-disp-kebab.ymin, r-boot-a.ymin)
#assert.eq(r-disp-kebab.ymax, r-boot-a.ymax)

// Empty input collapses to none.
#let r-empty = mean-cl-boot(())
#assert.eq(r-empty.y, none)
#assert.eq(r-empty.ymin, none)
#assert.eq(r-empty.ymax, none)

Loose-ends tests passed.
