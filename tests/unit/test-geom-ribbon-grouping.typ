// `geom-ribbon` has an identity stat, so render does not partition before the
// geom; the band must split into one polygon per group at draw time. A discrete
// `fill` mapping must train discrete and `partition-by-group` (the call
// ribbon's `draw()` makes) must emit one group per level rather than pooling
// every row into a single ribbon.

#import "../../src/render.typ": _prepare-layer
#import "../../src/scale/train.typ": train
#import "../../src/utils/group.typ": partition-by-group
#import "../../src/aes.typ": aes
#import "../../src/geom/ribbon.typ": geom-ribbon

#let raw = (
  (x: 0, lo: -1, hi: 1, grp: "a"),
  (x: 1, lo: -0.5, hi: 1.5, grp: "a"),
  (x: 2, lo: 0, hi: 2, grp: "a"),
  (x: 0, lo: 2, hi: 4, grp: "b"),
  (x: 1, lo: 2.5, hi: 4.5, grp: "b"),
  (x: 2, lo: 3, hi: 5, grp: "b"),
)

#let mapping = aes(x: "x", ymin: "lo", ymax: "hi", fill: "grp")
#let layers = (geom-ribbon(alpha: 0.4),)
#let prepared = layers.map(l => _prepare-layer(l, mapping, raw))

// A discrete fill mapping must train discrete; otherwise scale-aware
// partitioning pools every row into `_all`.
#let trained = train(layers: prepared, mapping: mapping, data: raw)
#assert.eq(trained.fill.type, "discrete")
#assert.eq(trained.fill.domain, ("a", "b"))

// With fill trained discrete, the partition ribbon performs at draw time emits
// one band per group rather than a single merged polygon.
#let prep = prepared.at(0)
#let groups = partition-by-group(prep.data, prep.mapping, trained: trained)
#assert.eq(groups.len(), 2)

geom-ribbon grouping tests passed.
