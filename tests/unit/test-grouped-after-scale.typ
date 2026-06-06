// A late-binding `after-scale`/`stage` marker on a grouping aesthetic must not
// panic the grouping layer or a grouped geom's stat. Regression for #48: the
// post-stat decomposition turns `stage(start: "g", after-scale: ...)` into an
// `after-scale` marker carrying `source: "g"`, a dictionary that `group-key`
// and `stat-smooth` previously fed straight into `row.at(...)`.

#import "../../src/utils/group.typ": group-cols, partition-by-group
#import "../../src/utils/late-binding.typ": after-scale, stage
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/aes.typ": aes
#import "../../src/geom/smooth.typ": geom-smooth
#import "../../src/geom/line.typ": geom-line

// A stage-derived marker (carries a `source` column) groups by that column.
#let sourced = (..after-scale((c, _) => c), source: "g")
// A pure `after-scale` closure carries no source, so it must not group.
#let pure = after-scale((v, _) => v)

#let rows = ((x: 1, g: "a"), (x: 2, g: "a"), (x: 3, g: "b"), (x: 4, g: "b"))

// group-cols unwraps the sourced marker to its column and skips the pure one.
#assert.eq(group-cols((x: "x", colour: sourced)), ("g",))
#assert.eq(group-cols((x: "x", colour: pure)), ())

// Scale-aware partition groups by the sourced marker's column...
#let trained = (colour: (type: "discrete", domain: ("a", "b")))
#assert.eq(
  partition-by-group(rows, (x: "x", colour: sourced), trained: trained).len(),
  2,
)
// ...and a pure after-scale marker pools into a single group.
#assert.eq(
  partition-by-group(rows, (x: "x", colour: pure), trained: trained).len(),
  1,
)

// stat-smooth's own grouping must survive a pure after-scale marker (the case
// that previously panicked inside `stat/smooth.typ`).
#let sdata = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "a"),
  (x: 3, y: 3, g: "b"),
  (x: 4, y: 5, g: "b"),
)
#let prep-pure = _prepare-layer(
  geom-smooth(method: "lm"),
  aes(x: "x", y: "y", colour: pure),
  sdata,
)
#assert(prep-pure.data.len() > 0)

// A stage marker through the full prepare pipeline (smooth and line) must not
// panic and keeps the two groups.
#let prep-smooth = _prepare-layer(
  geom-smooth(method: "lm"),
  aes(x: "x", y: "y", colour: stage(start: "g", after-scale: (c, _) => c)),
  sdata,
)
#assert(prep-smooth.data.len() > 0)
#let prep-line = _prepare-layer(
  geom-line(),
  aes(x: "x", y: "y", colour: stage(start: "g", after-scale: (c, _) => c)),
  sdata,
)
#assert.eq(
  partition-by-group(
    prep-line.data,
    prep-line.mapping,
    trained: trained,
  ).len(),
  2,
)

grouped after-scale/stage tests passed.
