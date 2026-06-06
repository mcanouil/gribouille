// `as-factor` annotations on grouping aesthetics must survive a non-identity
// stat (e.g., `stat-bin` under `geom-freqpoly`) so the colour scale trains
// discrete and `partition-by-group` emits one group per level rather than
// pooling everything into `_all`.

#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/scale/train.typ": train
#import "../../src/utils/group.typ": partition-by-group
#import "../../src/data.typ": as-factor
#import "../../src/aes.typ": aes
#import "../../src/geom/freqpoly.typ": geom-freqpoly

#let raw = (
  (x: 1.0, g: 4),
  (x: 1.5, g: 4),
  (x: 2.0, g: 4),
  (x: 2.5, g: 4),
  (x: 1.2, g: 6),
  (x: 1.8, g: 6),
  (x: 2.4, g: 6),
  (x: 2.9, g: 6),
)

#let mapping = aes(x: "x", colour: as-factor("g"))
#let layers = (geom-freqpoly(bins: 4, stroke: 1pt),)
#let prepared = layers.map(l => _prepare-layer(l, mapping, raw))

// The post-stat layer mapping must still carry the `as-factor` wrapper on
// `colour`; otherwise scale training infers numeric and partition pools
// every row into `_all`.
#let trained = train(layers: prepared, mapping: mapping, data: raw)
#assert.eq(trained.colour.type, "discrete")
#assert.eq(trained.colour.domain, ("4", "6"))

// With the colour scale trained discrete, scale-aware partitioning emits
// one group per cylinder count rather than a single pooled line.
#let prep = prepared.at(0)
#let groups = partition-by-group(prep.data, prep.mapping, trained: trained)
#assert.eq(groups.len(), 2)

stat-bin grouping tests passed.
