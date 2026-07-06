// Alpha scale family unit tests.

#import "../../src/scale/colour.typ": (
  _alpha-binned, _alpha-continuous, _alpha-identity, _alpha-manual,
)
#import "../../src/utils/level-resolve.typ": resolve-level

// scale-continuous spec dict shape.
#let sc = _alpha-continuous(range: (0.2, 1))
#assert.eq(sc.kind, "scale")
#assert.eq(sc.aesthetic, "alpha")
#assert.eq(sc.type, "continuous")
#assert.eq(sc.range, (0.2, 1))

// scale-identity passthrough, no legend.
#let si = _alpha-identity()
#assert.eq(si.aesthetic, "alpha")
#assert.eq(si.type, "identity")

// scale-manual: per-level opacities.
#let sm = _alpha-manual(values: (0.2, 0.55, 1))
#assert.eq(sm.kind, "scale")
#assert.eq(sm.aesthetic, "alpha")
#assert.eq(sm.type, "discrete")
#assert.eq(sm.palette, (0.2, 0.55, 1))

// scale-binned: continuous with binned flag.
#let sb = _alpha-binned(n-breaks: 5, range: (0.2, 1))
#assert.eq(sb.kind, "scale")
#assert.eq(sb.aesthetic, "alpha")
#assert.eq(sb.type, "continuous")
#assert.eq(sb.binned, true)
#assert.eq(sb.n-breaks, 5)
#assert.eq(sb.range, (0.2, 1))

// resolve-level honours the manual palette.
#let trained-manual = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: sm,
)
#assert.eq(resolve-level("alpha", trained-manual, "a"), 0.2)
#assert.eq(resolve-level("alpha", trained-manual, "b"), 0.55)
#assert.eq(resolve-level("alpha", trained-manual, "c"), 1)

// Discrete inference without an explicit palette spreads the range evenly.
#let trained-discrete = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: (aesthetic: "alpha", type: "discrete", range: (0.2, 1)),
)
#assert.eq(resolve-level("alpha", trained-discrete, "a"), 0.2)
#assert.eq(resolve-level("alpha", trained-discrete, "c"), 1)

Alpha scale family tests passed.
