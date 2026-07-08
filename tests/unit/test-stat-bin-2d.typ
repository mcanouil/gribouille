// Two-dimensional rectangular binning. `stat-bin-2d` partitions (x, y) into
// a grid and emits one row per non-empty cell with corners and a count.

#import "../../src/aes.typ": aes
#import "../../src/stat/bin-2d.typ": apply, stat-bin-2d
#import "../../src/utils/bin-2d.typ": (
  bin-grid-2d, bin-of-2d, panel-bin-grid-2d, resolve-bin-grid-2d,
)

// --- spec dict shape ---

#let s = stat-bin-2d(bins: 4)
#assert.eq(s.kind, "stat")
#assert.eq(s.name, "bin-2d")
#assert.eq(s.params.bins, 4)
#assert.eq(s.params.binwidth, none)

// --- bin-grid-2d resolves scalar / pair inputs ---

#let xs = (0.0, 1.0, 2.0, 3.0)
#let ys = (10.0, 20.0, 30.0, 40.0)

#let g-scalar = bin-grid-2d(xs, ys, 3, none)
#assert.eq(g-scalar.x-n-bins, 3)
#assert.eq(g-scalar.y-n-bins, 3)
#assert.eq(g-scalar.x-lo, 0.0)
#assert.eq(g-scalar.y-lo, 10.0)

#let g-pair = bin-grid-2d(xs, ys, (4, 2), none)
#assert.eq(g-pair.x-n-bins, 4)
#assert.eq(g-pair.y-n-bins, 2)

// binwidth wins when supplied; scalar applies to both axes.
#let g-bw = bin-grid-2d(xs, ys, 30, 1.5)
#assert.eq(g-bw.x-width, 1.5)
#assert.eq(g-bw.y-width, 1.5)

// --- bin-of-2d clamps to grid extents ---

#let grid = bin-grid-2d(xs, ys, (3, 3), none)
#assert.eq(bin-of-2d(0.0, 10.0, grid), (0, 0))
#assert.eq(bin-of-2d(3.0, 40.0, grid), (2, 2))

// --- apply emits per-cell rows with corners and a count ---

#let raw = (
  (a: 0.5, b: 0.5),
  (a: 0.7, b: 0.7),
  (a: 1.5, b: 0.5),
  (a: 1.5, b: 1.5),
  (a: 1.5, b: 1.5),
)
#let r = apply(raw, aes(x: "a", y: "b"), params: (bins: 2, binwidth: none))
#assert.eq(r.mapping.fill, "_count")
#assert.eq(r.mapping.xmin, "xmin")
#assert.eq(r.mapping.ymax, "ymax")
#assert.eq(r.data.len(), 3)
#let total = r.data.fold(0, (acc, row) => acc + row._count)
#assert.eq(total, 5)
// Two bins reach count 2: (0.5, 0.5)+(0.7, 0.7) and the doubled (1.5, 1.5).
#let big = r.data.filter(row => row._count == 2)
#assert.eq(big.len(), 2)
#let top-right = big.filter(row => row.x > 1.0 and row.y > 1.0)
#assert.eq(top-right.len(), 1)
#assert.eq(top-right.at(0).x, 1.25)
#assert.eq(top-right.at(0).y, 1.25)
#assert.eq(top-right.at(0).xmax, 1.5)

// _density is each cell's fraction of the total count and sums to 1.
#let density-sum = r.data.fold(0.0, (acc, row) => acc + row._density)
#assert(calc.abs(density-sum - 1.0) < 1e-9)
#assert.eq(top-right.at(0)._density, 2 / 5)

// --- panel grid is reused via params.grid ---

#let panel-params = panel-bin-grid-2d(
  raw,
  aes(x: "a", y: "b"),
  (bins: 4, binwidth: none),
)
#assert.eq(panel-params.grid.x-n-bins, 4)
#let resolved = resolve-bin-grid-2d((), (), panel-params)
#assert.eq(resolved.x-n-bins, 4)

// Empty input: no rows emitted.
#let r-empty = apply((), aes(x: "a", y: "b"), params: (bins: 2, binwidth: none))
#assert.eq(r-empty.data, ())

stat-bin-2d tests passed.
