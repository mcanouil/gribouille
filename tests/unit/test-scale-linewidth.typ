// Linewidth scale family unit tests.

#import "../../src/scale/linewidth.typ": (
  _linewidth-binned, _linewidth-continuous, _linewidth-identity,
  _linewidth-manual,
)
#import "../../src/utils/level-resolve.typ": resolve-level

// scale-continuous: spec dict shape.
#let sc = _linewidth-continuous(range: (0.5pt, 3pt))
#assert.eq(sc.kind, "scale")
#assert.eq(sc.aesthetic, "linewidth")
#assert.eq(sc.type, "continuous")
#assert.eq(sc.range, (0.5pt, 3pt))

// scale-identity: identity passthrough, no legend.
#let si = _linewidth-identity()
#assert.eq(si.aesthetic, "linewidth")
#assert.eq(si.type, "identity")

// scale-manual: per-level Typst lengths.
#let sm = _linewidth-manual(values: (0.4pt, 1pt, 2pt))
#assert.eq(sm.kind, "scale")
#assert.eq(sm.aesthetic, "linewidth")
#assert.eq(sm.type, "discrete")
#assert.eq(sm.palette, (0.4pt, 1pt, 2pt))

// scale-binned: continuous with binned flag.
#let sb = _linewidth-binned(n-breaks: 5, range: (0.4pt, 2pt))
#assert.eq(sb.kind, "scale")
#assert.eq(sb.aesthetic, "linewidth")
#assert.eq(sb.type, "continuous")
#assert.eq(sb.binned, true)
#assert.eq(sb.n-breaks, 5)
#assert.eq(sb.range, (0.4pt, 2pt))

// resolve-level honours the manual palette: each level reads its supplied length.
#let trained-manual = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: sm,
)
#assert.eq(resolve-level("linewidth", trained-manual, "a"), 0.4pt)
#assert.eq(resolve-level("linewidth", trained-manual, "b"), 1pt)
#assert.eq(resolve-level("linewidth", trained-manual, "c"), 2pt)

// Discrete inference without an explicit palette spreads the range evenly.
#let trained-discrete = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: (aesthetic: "linewidth", type: "discrete", range: (1pt, 3pt)),
)
#assert.eq(resolve-level("linewidth", trained-discrete, "a"), 1pt)
#assert.eq(resolve-level("linewidth", trained-discrete, "c"), 3pt)

Linewidth scale family tests passed.
