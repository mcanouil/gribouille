// Stroke scale family unit tests.

#import "../../src/scale/stroke.typ": (
  _stroke-binned, _stroke-continuous, _stroke-identity, _stroke-manual,
)
#import "../../src/utils/level-resolve.typ": resolve-level

#let sc = _stroke-continuous(range: (0.2pt, 1.6pt))
#assert.eq(sc.kind, "scale")
#assert.eq(sc.aesthetic, "stroke")
#assert.eq(sc.type, "continuous")
#assert.eq(sc.range, (0.2pt, 1.6pt))

#let si = _stroke-identity()
#assert.eq(si.aesthetic, "stroke")
#assert.eq(si.type, "identity")

#let sm = _stroke-manual(values: (0.2pt, 0.8pt, 1.6pt))
#assert.eq(sm.aesthetic, "stroke")
#assert.eq(sm.type, "discrete")
#assert.eq(sm.palette, (0.2pt, 0.8pt, 1.6pt))

#let sb = _stroke-binned(n-breaks: 5)
#assert.eq(sb.aesthetic, "stroke")
#assert.eq(sb.binned, true)
#assert.eq(sb.n-breaks, 5)

// resolve-level honours the manual palette per-level.
#let trained-manual = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: sm,
)
#assert.eq(resolve-level("stroke", trained-manual, "a"), 0.2pt)
#assert.eq(resolve-level("stroke", trained-manual, "b"), 0.8pt)
#assert.eq(resolve-level("stroke", trained-manual, "c"), 1.6pt)

// Discrete inference without a palette spreads the range evenly.
#let trained-discrete = (
  type: "discrete",
  domain: ("a", "b", "c"),
  spec: (aesthetic: "stroke", type: "discrete", range: (0.2pt, 1.6pt)),
)
#assert.eq(resolve-level("stroke", trained-discrete, "a"), 0.2pt)
#assert.eq(resolve-level("stroke", trained-discrete, "c"), 1.6pt)

scale-stroke family tests passed.
