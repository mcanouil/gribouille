// Scale training and mapping tests.

#import "../../src/scale/train.typ": (
  map-continuous, map-discrete, map-position, train,
)
#import "../../src/geom/point.typ": geom-point
#import "../../src/aes.typ": aes

#let df = (
  (x: 1, y: 10, g: "a"),
  (x: 2, y: 20, g: "b"),
  (x: 3, y: 30, g: "a"),
)

#let layers = (geom-point(),)
#let trained = train(
  layers: layers,
  mapping: aes(x: "x", y: "y", colour: "g"),
  data: df,
)

#assert.eq(trained.x.type, "continuous")
#assert.eq(trained.x.domain, (1.0, 3.0))
#assert.eq(trained.y.type, "continuous")
#assert.eq(trained.y.domain, (10.0, 30.0))
#assert.eq(trained.colour.type, "discrete")
#assert.eq(trained.colour.domain, ("a", "b"))

#assert.eq(map-continuous(2.0, (1.0, 3.0), (0.0, 10.0)), 5.0)
#assert.eq(map-continuous(1.0, (1.0, 3.0), (0.0, 10.0)), 0.0)
#assert.eq(map-continuous(3.0, (1.0, 3.0), (0.0, 10.0)), 10.0)

#assert.eq(map-discrete("a", ("a", "b"), (0.0, 10.0)), 2.5)
#assert.eq(map-discrete("b", ("a", "b"), (0.0, 10.0)), 7.5)

// Reversed discrete mapping mirrors positions around the range midpoint
// so the first level lands at the far end (used by coord-flip on y).
#assert.eq(map-discrete("a", ("a", "b"), (0.0, 10.0), reverse: true), 7.5)
#assert.eq(map-discrete("b", ("a", "b"), (0.0, 10.0), reverse: true), 2.5)

#assert.eq(map-position(trained.x, "2", (0.0, 10.0)), 5.0)
#assert.eq(map-position(trained.colour, "a", (0.0, 10.0)), 2.5)

// `map-position` forwards the `reverse` flag from a discrete trained scale.
#let rev-trained = (
  type: "discrete",
  domain: ("a", "b", "c", "d"),
  reverse: true,
)
#assert.eq(map-position(rev-trained, "a", (0.0, 100.0)), 87.5)
#assert.eq(map-position(rev-trained, "d", (0.0, 100.0)), 12.5)

Scale tests passed.
