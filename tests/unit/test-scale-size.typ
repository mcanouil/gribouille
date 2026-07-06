// scale-size manual + scale-radius unit tests.

#import "../../src/scale/size.typ": _size-area, _size-continuous, _size-manual
#import "../../src/utils/level-resolve.typ": resolve-level

// scale-manual spec dict shape.
#let sm = _size-manual(values: (2pt, 4pt, 7pt))
#assert.eq(sm.kind, "scale")
#assert.eq(sm.aesthetic, "size")
#assert.eq(sm.type, "discrete")
#assert.eq(sm.palette, (2pt, 4pt, 7pt))

// scale-radius is a linear value-to-radius scale; it shares "size" aesthetic
// with scale-size-* but signals the linear-radius intent in user code.
#let sr = _size-continuous(range: (1pt, 8pt))
#assert.eq(sr.aesthetic, "size")
#assert.eq(sr.type, "continuous")
#assert.eq(sr.range, (1pt, 8pt))
// scale-radius leaves no `size-trans` flag on the spec, so resolve-size
// stays on the linear branch (unlike scale-area which sets "area").
#assert.eq(sr.at("size-trans", default: none), none)
#assert.eq(_size-area().size-trans, "area")

// resolve-level honours the manual palette per-level.
#let trained-manual = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: sm,
)
#assert.eq(resolve-level("size", trained-manual, "a"), 2pt)
#assert.eq(resolve-level("size", trained-manual, "b"), 4pt)
#assert.eq(resolve-level("size", trained-manual, "c"), 7pt)

// Discrete inference without an explicit palette spreads the range evenly.
#let trained-discrete = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: (aesthetic: "size", type: "discrete", range: (1pt, 7pt)),
)
#assert.eq(resolve-level("size", trained-discrete, "a"), 1pt)
#assert.eq(resolve-level("size", trained-discrete, "c"), 7pt)

scale-size manual + scale-radius tests passed.
