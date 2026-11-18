// Statistical transformation tests.

#import "../../src/stat/apply.typ": apply-stat

// --- stat-count: single group (no fill/colour) ---

#let df-simple = (
  (cat: "a"),
  (cat: "b"),
  (cat: "a"),
  (cat: "c"),
  (cat: "a"),
)
#let m-simple = (x: "cat")

#let r-simple = apply-stat("count", df-simple, m-simple, (:))

// Output uses original column name, not "x".
#assert.eq(r-simple.data.at(0).at("cat"), "a")
#assert.eq(r-simple.data.at(0).at("_count"), 3)
#assert.eq(r-simple.data.at(1).at("cat"), "b")
#assert.eq(r-simple.data.at(1).at("_count"), 1)
#assert.eq(r-simple.data.at(2).at("cat"), "c")
#assert.eq(r-simple.data.at(2).at("_count"), 1)

// Mapping: x unchanged, y → "_count".
#assert.eq(r-simple.mapping.x, "cat")
#assert.eq(r-simple.mapping.y, "_count")

// --- stat-count: order preserved (first-appearance) ---

#let df-order = (
  (v: "b"),
  (v: "a"),
  (v: "b"),
  (v: "c"),
)
#let r-order = apply-stat("count", df-order, (x: "v"), (:))
#assert.eq(r-order.data.at(0).at("v"), "b")
#assert.eq(r-order.data.at(1).at("v"), "a")
#assert.eq(r-order.data.at(2).at("v"), "c")

// --- stat-count: none and empty-string values count as one NA bucket ---

#let df-nones = (
  (v: "a"),
  (v: none),
  (v: ""),
  (v: "a"),
)
#let r-nones = apply-stat("count", df-nones, (x: "v"), (:))
#assert.eq(r-nones.data.len(), 2)
#assert.eq(r-nones.data.at(0).at("_count"), 2)
#assert.eq(r-nones.data.at(1).at("v"), none)
#assert.eq(r-nones.data.at(1).at("_count"), 2)

// --- stat-bin: preserves grouping aesthetics in output mapping ---
//
// Per-group apply on a single group still publishes the input mapping's
// `fill` so downstream geoms/positions see per-bin grouping.
#let df-bin = range(0, 10).map(i => (x: i, g: "a"))
#let r-bin = apply-stat("bin", df-bin, (x: "x", fill: "g"), (bins: 4))
#assert.eq(r-bin.mapping.x, "x")
#assert.eq(r-bin.mapping.y, "y")
#assert.eq(r-bin.mapping.fill, "g")

// --- stat-bindot: same grouping preservation for dotplot binning ---

#let r-bindot = apply-stat(
  "bindot",
  df-bin,
  (x: "x", colour: "g"),
  (bins: 4),
)
#assert.eq(r-bindot.mapping.x, "x")
#assert.eq(r-bindot.mapping.y, "y")
#assert.eq(r-bindot.mapping.colour, "g")

// --- stat-sum: preserves grouping while still publishing size: "_n" --

#let df-sum = (
  (x: 1, y: 1, g: "a"),
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "b"),
)
#let r-sum = apply-stat("sum", df-sum, (x: "x", y: "y", fill: "g"), (:))
#assert.eq(r-sum.mapping.x, "x")
#assert.eq(r-sum.mapping.y, "y")
#assert.eq(r-sum.mapping.size, "_n")
#assert.eq(r-sum.mapping.fill, "g")

// --- stat-qq / stat-qq-line: preserve grouping; drop stale `sample` key ---

#let df-qq = range(1, 6).map(i => (v: i, g: "a"))
#let r-qq = apply-stat("qq", df-qq, (y: "v", colour: "g"), (:))
#assert.eq(r-qq.mapping.x, "theoretical")
#assert.eq(r-qq.mapping.y, "sample")
#assert.eq(r-qq.mapping.colour, "g")
#assert.eq(r-qq.mapping.at("sample", default: none), none)

#let r-qql = apply-stat(
  "qq-line",
  df-qq,
  (sample: "v", colour: "g"),
  (:),
)
#assert.eq(r-qql.mapping.colour, "g")
#assert.eq(r-qql.mapping.at("sample", default: none), none)

// --- stat-summary-bin: preserves grouping alongside synthesised columns ---

#let df-sb = range(0, 10).map(i => (x: i, y: i * 2.0, g: "a"))
#let r-sb = apply-stat(
  "summary-bin",
  df-sb,
  (x: "x", y: "y", fill: "g"),
  (bins: 3, fun: "mean-se"),
)
#assert.eq(r-sb.mapping.x, "x")
#assert.eq(r-sb.mapping.y, "y")
#assert.eq(r-sb.mapping.ymin, "ymin")
#assert.eq(r-sb.mapping.ymax, "ymax")
#assert.eq(r-sb.mapping.fill, "g")

Stat tests passed.

// --- stat-sum: none and "" are one missing cell, written back as none ---
#let r-sum = apply-stat(
  "sum",
  ((a: "x", b: "y"), (a: none, b: "y"), (a: "", b: "y")),
  (x: "a", y: "b"),
  (:),
)
#assert.eq(r-sum.data.len(), 2)
#assert.eq(r-sum.data.map(r => r.x), ("x", none))
