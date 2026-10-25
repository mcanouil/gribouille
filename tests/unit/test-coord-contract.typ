// The coord contract: every constructor carries `train` and `panel-size`, and
// the renderer calls them instead of branching on the coord name.

#import "../../lib.typ": aes, geom-point, plot
#import "../../src/coord/contract.typ": coord-base
#import "../../src/coord/resolve.typ": resolve-coord
#import "../../src/coord/cartesian.typ": coord-cartesian
#import "../../src/coord/fixed.typ": coord-fixed
#import "../../src/coord/flip.typ": coord-flip
#import "../../src/coord/radial.typ": coord-radial
#import "../../src/coord/transform.typ": coord-transform

#for c in (
  coord-cartesian(),
  coord-fixed(),
  coord-flip(),
  coord-radial(),
  coord-transform(),
) {
  assert.eq(type(c.train), function, message: c.name)
  assert.eq(type(c.panel-size), function, message: c.name)
}

#assert.eq(coord-flip().flipped, true)
#assert.eq(coord-cartesian().flipped, false)

// The flip swaps x and y and reverses a discrete post-flip y.
#let trained = (
  x: (type: "discrete", domain: ("a", "b", "c")),
  y: (type: "continuous", domain: (0, 10)),
)
#let flipped = (coord-flip().train)(trained)
#assert.eq(flipped.x.type, "continuous")
#assert.eq(flipped.x.domain, (0, 10))
#assert.eq(flipped.y.type, "discrete")
#assert.eq(flipped.y.domain, ("a", "b", "c"))
#assert.eq(flipped.y.reverse, true)

// Pinned against `_fixed-inner-size` before the move into `coord-fixed`.
#let wide = (
  x: (type: "continuous", domain: (0, 20)),
  y: (type: "continuous", domain: (0, 4)),
)
#assert.eq((coord-fixed(ratio: 1).panel-size)(wide, 10, 6), (10, 2.0))

// A coord built from `coord-base` reaches the renderer through its functions.
#let halve = coord-base("halve") + (panel-size: (t, w, h) => (w / 2, h))
#let _ = plot(
  data: ((x: 1, y: 1), (x: 2, y: 3)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  coord: halve,
  width: 6cm,
  height: 4cm,
)

#assert.eq(resolve-coord(none).name, "cartesian")

Coord contract tests passed.
