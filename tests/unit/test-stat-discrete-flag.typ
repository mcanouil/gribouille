// A layer decides once whether an axis is discrete, and the stats follow it.
// A missing cell is the missing level on a discrete axis, whatever the cells of
// one group infer.

#import "../../src/render/prestat.typ": layer-discrete
#import "../../src/stat/count.typ" as count-stat
#import "../../src/stat/sum.typ" as sum-stat
#import "../../src/stat/summary.typ" as summary-stat
#import "../../src/position/stack.typ" as stack
#import "../../src/data.typ": as-factor
#import "../../src/utils/late-binding.typ": after-stat
#import "../../src/utils/types.typ": axis-discrete

#let flags(x: false, y: false) = (x: x, y: y)

// The helper reads the flag when there is one, the cells otherwise.
#assert(axis-discrete((x: true), "x", ((x: 1),), "x"))
#assert(not axis-discrete((x: false), "x", ((x: "a"),), "x"))
#assert(axis-discrete(none, "x", ((x: "a"),), "x"))
#assert(not axis-discrete(none, "x", ((x: 1),), "x"))

// Count: a forced-discrete numeric x keeps its missing cell as the NA row.
#let numeric = ((x: 1), (x: 2), (x: none))
#assert.eq(count-stat.apply(numeric, (x: "x")).data.len(), 2)
#assert.eq(
  count-stat
    .apply(numeric, (x: "x"), params: (discrete: flags(x: true)))
    .data
    .len(),
  3,
)

// Count: a group whose x cells are all missing still counts them, because the
// layer says x is discrete.
#let empty = ((x: none), (x: none))
#let r = count-stat.apply(empty, (x: "x"), params: (discrete: flags(x: true)))
#assert.eq(r.data.len(), 1)
#assert.eq(r.data.first().at("_count"), 2)

// Sum: both axes follow their flag.
#let grid = ((x: 1, y: none), (x: 1, y: none), (x: 2, y: 3))
#assert.eq(sum-stat.apply(grid, (x: "x", y: "y")).data.len(), 1)
#assert.eq(
  sum-stat
    .apply(
      grid,
      (x: "x", y: "y"),
      params: (discrete: flags(x: true, y: true)),
    )
    .data
    .len(),
  2,
)

// Summary: the missing level of a forced-discrete x has its own row.
#let obs = ((x: 1, y: 1), (x: none, y: 2), (x: none, y: 4))
#assert.eq(summary-stat.apply(obs, (x: "x", y: "y")).data.len(), 1)
#assert.eq(
  summary-stat
    .apply(
      obs,
      (x: "x", y: "y"),
      params: (discrete: flags(x: true)),
    )
    .data
    .len(),
  2,
)

// Stack: the missing x of a forced-discrete axis is a bucket of its own, so
// its row is stacked and gets ymin and ymax.
#let stackable = ((x: 1, y: 1), (x: none, y: 2))
#let plain = stack.apply(stackable, (x: "x", y: "y"))
#let forced = stack.apply(
  stackable,
  (x: "x", y: "y"),
  params: (discrete: flags(x: true)),
)
#assert.eq(plain.data.filter(r => r.at("ymin", default: none) != none).len(), 1)
#assert.eq(
  forced.data.filter(r => r.at("ymin", default: none) != none).len(),
  2,
)

// The layer flags: a forced type wins, then a user discrete scale, then the
// whole layer data.
#let layer = ((x: 1, g: "a"), (x: none, g: none))
#assert.eq(layer-discrete((x: "x", y: "g"), layer, (:)), (x: false, y: true))
#assert.eq(
  layer-discrete((x: as-factor("x"), y: "g"), layer, (:)),
  (x: true, y: true),
)
#assert.eq(
  layer-discrete((x: "x"), layer, (x: (type: "discrete"))),
  (x: true, y: false),
)
#assert.eq(layer-discrete((x: "x"), ((x: none), (x: none)), (:)).x, false)

// An `after-stat` axis has no column before the stat runs, so it is not
// discrete yet and the call does not fail on the marker.
#assert.eq(
  layer-discrete((x: "x", y: after-stat("count")), layer, (:)),
  (x: false, y: false),
)
