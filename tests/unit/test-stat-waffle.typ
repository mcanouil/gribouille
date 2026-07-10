// stat-waffle: counts to column-major unit grid cells.

#import "../../src/stat/waffle.typ": apply, setup, stat-waffle
#import "../../src/stat/info.typ": stat-info, stat-names

#let s = stat-waffle()
#assert.eq(s.kind, "stat")
#assert.eq(s.name, "waffle")
#assert.eq(s.params.rows, 10)

// --- pre-aggregated counts via the weight aesthetic ---------------------------
// Groups tile in first-appearance order: a gets cells 0-4, b cells 5-7.
// rows = 3, column-major bottom-up: idx -> (quo(idx, 3) + 1, rem(idx, 3) + 1).

#let d = ((k: "a", n: 5), (k: "b", n: 3))
#let mapping = (fill: "k", weight: "n")
#let resolved = setup(d, mapping, params: (rows: 3))
#assert.eq(resolved.starts.at("a"), (start: 0, count: 5))
#assert.eq(resolved.starts.at("b"), (start: 5, count: 3))

#let ra = apply((d.first(),), mapping, params: resolved)
#assert.eq(ra.mapping.x, "x")
#assert.eq(ra.mapping.y, "y")
#assert.eq(ra.data.len(), 5)
#assert.eq(ra.data.map(c => (c.x, c.y)), (
  (1, 1),
  (1, 2),
  (1, 3),
  (2, 1),
  (2, 2),
))
// Source columns survive on every cell.
#assert(ra.data.all(c => c.k == "a" and c.n == 5))

#let rb = apply((d.last(),), mapping, params: resolved)
#assert.eq(rb.data.map(c => (c.x, c.y)), ((2, 3), (3, 1), (3, 2)))

// --- one cell per row without weights -----------------------------------------

#let raw = (("a",) * 4 + ("b",) * 2).map(k => (k: k))
#let raw-mapping = (fill: "k")
#let raw-resolved = setup(raw, raw-mapping, params: (rows: 2))
#assert.eq(raw-resolved.starts.at("a"), (start: 0, count: 4))
#assert.eq(raw-resolved.starts.at("b"), (start: 4, count: 2))
#let r-raw = apply(
  raw.filter(r => r.k == "b"),
  raw-mapping,
  params: raw-resolved,
)
#assert.eq(r-raw.data.map(c => (c.x, c.y)), ((3, 1), (3, 2)))

// --- fractional weights round to the nearest cell ------------------------------

#let frac = ((k: "a", n: 2.6),)
#let frac-resolved = setup(frac, (fill: "k", weight: "n"), params: (rows: 5))
#assert.eq(frac-resolved.starts.at("a").count, 3)

// --- empty groups emit nothing --------------------------------------------------

#let zero = ((k: "a", n: 0),)
#let zero-resolved = setup(zero, (fill: "k", weight: "n"), params: (rows: 5))
#let r-zero = apply(zero, (fill: "k", weight: "n"), params: zero-resolved)
#assert.eq(r-zero.data.len(), 0)

#assert.eq(stat-info("waffle").outputs, ("x", "y"))
#assert("waffle" in stat-names())

stat-waffle tests passed.
