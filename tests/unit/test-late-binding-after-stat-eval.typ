// `eval-after-stat` resolves `after-stat` markers against post-stat rows.
// String exprs rewrite the mapping to that column; function exprs run
// per row and synthesise an `_as_<channel>` column. End-to-end, an
// `after-stat("_count")` mapping must match the implicit `geom-bar()`
// y binding pixel-for-pixel through scale training.

#import "../../src/utils/late-binding.typ": after-stat, eval-after-stat
#import "../../src/aes.typ": aes
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/scale/train.typ": train
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/grey.typ": theme-grey
#import "../../src/geom/bar.typ": geom-bar

#let rows = ((x: "a", _count: 3), (x: "b", _count: 5))

// --- string expr: rewrite the mapping field ----------------------------

#let r = eval-after-stat(rows, (x: "x", y: after-stat("_count")), (:))
#assert.eq(r.mapping.y, "_count")
#assert.eq(r.mapping.x, "x")
#assert.eq(r.rows, rows)

// --- function expr: synthesised `_as_<channel>` column -----------------

#let r2 = eval-after-stat(
  rows,
  (x: "x", y: after-stat((row, _) => row._count * 2)),
  (:),
)
#assert.eq(r2.mapping.y, "_as_y")
#assert.eq(r2.rows.at(0)._as_y, 6)
#assert.eq(r2.rows.at(1)._as_y, 10)

// --- no-op when mapping carries no markers -----------------------------

#let r3 = eval-after-stat(rows, (x: "x", y: "_count"), (:))
#assert.eq(r3.rows, rows)
#assert.eq(r3.mapping.y, "_count")

// --- end-to-end: after-stat("_count") matches geom-bar() y baseline ---

#let theme = merge-theme(theme-grey())
#let raw = (
  (grp: "a"),
  (grp: "b"),
  (grp: "a"),
  (grp: "c"),
  (grp: "a"),
  (grp: "b"),
)

#let baseline = geom-bar(mapping: aes(x: "grp"))
#let baseline-prep = _prepare-layer(baseline, none, raw, theme: theme)

#let aliased = geom-bar(mapping: aes(x: "grp", y: after-stat("_count")))
#let aliased-prep = _prepare-layer(aliased, none, raw, theme: theme)

#assert.eq(baseline-prep.mapping.y, aliased-prep.mapping.y)
#assert.eq(baseline-prep.data, aliased-prep.data)

// --- train trains the late-bound channel and matches the baseline ------

#let trained-baseline = train(
  scales: (:),
  layers: (baseline-prep,),
  mapping: none,
  data: none,
)
#let trained-aliased = train(
  scales: (:),
  layers: (aliased-prep,),
  mapping: none,
  data: none,
)
#assert("y" in trained-aliased)
#assert.eq(trained-aliased.y.type, trained-baseline.y.type)
#assert.eq(trained-aliased.y.domain, trained-baseline.y.domain)

late-binding after-stat eval tests passed.
