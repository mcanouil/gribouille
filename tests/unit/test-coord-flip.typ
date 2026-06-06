// coord-flip: spec dictionary shape and renderer detection.

#import "../../src/coord/flip.typ": coord-flip
#import "../../src/render/domain.typ": _apply-flip, _is-flipped

#let c1 = coord-flip()
#assert.eq(c1.kind, "coord")
#assert.eq(c1.coord, "flip")
#assert.eq(c1.reverse, auto)

// The dict shape must stay stable so the renderer can route the spec into
// the flip swap without touching positional or fixed-aspect coords.
#let keys-c1 = c1.keys().sorted()
#assert.eq(keys-c1, ("coord", "kind", "reverse"))

// Explicit reverse values carry through the spec.
#assert.eq(coord-flip(reverse: true).reverse, true)
#assert.eq(coord-flip(reverse: false).reverse, false)

// `_is-flipped` recognises the flip coord and rejects everything else.
#assert.eq(_is-flipped(c1), true)
#assert.eq(_is-flipped((kind: "coord", coord: "cartesian")), false)
#assert.eq(_is-flipped((kind: "coord", coord: "fixed", ratio: 1)), false)
#assert.eq(_is-flipped(none), false)

// `_apply-flip` swaps trained.x and trained.y when the coord is flip,
// and is a no-op otherwise.
#let trained = (
  x: (type: "discrete", domain: ("a", "b", "c")),
  y: (type: "continuous", domain: (0, 10)),
)
#let flipped = _apply-flip(trained, c1)
#assert.eq(flipped.x.type, "continuous")
#assert.eq(flipped.x.domain, (0, 10))
#assert.eq(flipped.y.type, "discrete")
#assert.eq(flipped.y.domain, ("a", "b", "c"))
// Default `auto` policy reverses a discrete post-flip y.
#assert.eq(flipped.y.reverse, true)

// `reverse: false` opts out even when post-flip y is discrete.
#let opt-out = _apply-flip(trained, coord-flip(reverse: false))
#assert.eq(opt-out.y.at("reverse", default: false), false)

// Continuous x flipped to continuous y under default `auto` stays put.
#let cc = (
  x: (type: "continuous", domain: (0, 10)),
  y: (type: "continuous", domain: (0, 1)),
)
#let cc-flipped = _apply-flip(cc, c1)
#assert.eq(cc-flipped.y.at("transform", default: "identity"), "identity")

// Explicit `reverse: true` reverses a continuous post-flip y via a `reverse`
// flag, leaving any numeric transform intact.
#let cc-rev = _apply-flip(cc, coord-flip(reverse: true))
#assert.eq(cc-rev.y.reverse, true)
#assert.eq(cc-rev.y.at("transform", default: "identity"), "identity")

// A log10 x keeps its transform under flip + reverse (regression: the
// reverse used to overwrite the numeric transform with "reverse").
#let cc-log = (
  x: (type: "continuous", domain: (0, 3), transform: "log10"),
  y: (type: "continuous", domain: (0, 1)),
)
#let cc-log-rev = _apply-flip(cc-log, coord-flip(reverse: true))
#assert.eq(cc-log-rev.y.transform, "log10")
#assert.eq(cc-log-rev.y.reverse, true)

#let untouched = _apply-flip(trained, (kind: "coord", coord: "cartesian"))
#assert.eq(untouched.x.type, "discrete")
#assert.eq(untouched.y.type, "continuous")

coord-flip tests passed.
