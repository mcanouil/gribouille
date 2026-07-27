// Extended Wilkinson breaks (Talbot, Lin, and Hanrahan 2010), the default
// automatic placement for continuous scales. The search trades simplicity,
// coverage, and density off against each other, so these assert the published
// behaviour of the criteria rather than a step ladder.

#import "../../lib.typ": (
  aes, breaks-extended, geom-point, scale-continuous, scales,
)
#import "../../src/utils/extended.typ": extended
#import "../../src/utils/pretty.typ": pretty
#import "../../src/scale/train.typ": train
#import "../../src/render/axis-format.typ": _axis-breaks
#import "../../src/render/domain.typ": _apply-expand

// --- round numbers over familiar ranges ---

#assert.eq(extended(0, 100, m: 5), (0.0, 25.0, 50.0, 75.0, 100.0))
#assert.eq(extended(0, 1, m: 5), (0.0, 0.25, 0.5, 0.75, 1.0))
#assert.eq(extended(1.8, 5.7, m: 5), (2.0, 3.0, 4.0, 5.0))
#assert.eq(extended(0.001, 0.009, m: 5), (0.0025, 0.005, 0.0075))

// `m` is a target the density criterion trades away, not a promise, but a
// larger `m` still yields more ticks.
#assert(extended(0, 100, m: 10).len() > extended(0, 100, m: 3).len())

// A large `m` reaches the tick counts it needs: over 0 to 100 asking for 20
// steps by 5, which takes 21 candidate ticks. The search bound has to follow
// `m` rather than sit at a constant, or the answer silently falls back to the
// 11-tick sequence stepping by 10.
#let twenty = extended(0, 100, m: 20)
#assert.eq(twenty.len(), 21)
#assert.eq(twenty.at(1) - twenty.at(0), 5.0)
#assert.eq(extended(0, 100, m: 40).len(), 41)

// --- every break lies inside the requested interval ---

#let inside(lo, hi, breaks) = breaks.all(b => b >= lo and b <= hi)
#for (lo, hi) in ((12, 44), (-3.2, 8.9), (7500, 15000), (0, 0.35), (-1, 1)) {
  let breaks = extended(lo, hi, m: 5)
  assert(inside(lo, hi, breaks), message: "break outside " + repr((lo, hi)))
  assert(breaks.len() > 0, message: "no breaks for " + repr((lo, hi)))
}

// --- steps are uniform ---

#let steps(breaks) = range(breaks.len() - 1).map(i => (
  breaks.at(i + 1) - breaks.at(i)
))
#let uniform-steps = steps(extended(0, 97, m: 5))
#assert(uniform-steps.all(s => calc.abs(s - uniform-steps.first()) < 1e-9))

// --- whole-number scales keep whole breaks ---

#assert.eq(extended(2019.85, 2023.15, m: 5, integer: true), (
  2020.0,
  2021.0,
  2022.0,
  2023.0,
))
#assert(
  extended(0, 3, m: 5, integer: true).all(b => b == calc.round(b)),
)
// Without the flag a narrow range may still split below the unit.
#assert(extended(0, 1, m: 5).any(b => b != calc.round(b)))

// --- degenerate range keeps the single value centred ---

#assert.eq(extended(5, 5, m: 5), (4.5, 5, 5.5))
#assert.eq(extended(0, 0, m: 5), (-1.0, 0.0, 1.0))
// A reversed interval is read as its span, not as an empty one.
#assert.eq(extended(100, 0, m: 5), extended(0, 100, m: 5))

// --- intervals no candidate can serve report what they found ---

// An interval narrower than the whole step it is restricted to keeps the best
// sequence, whose ticks then all fall outside: the caller draws no tick rather
// than a fractional one. No axis reaches this, since a whole-numbered scale
// always spans at least one whole value, and neither does `breaks-extended`,
// which only sets `integer` when every value is whole.
#assert.eq(extended(0.2, 0.4, m: 5, integer: true), ())

// Below that, no candidate is scored at all and the interval itself comes
// back, so the result is never empty of information.
#assert.eq(extended(0.0001, 0.0002, m: 5, integer: true), (0.0001, 0.0002))

// --- it is the automatic axis placement ---

#let trained = _apply-expand(
  train(
    layers: (geom-point(),),
    mapping: aes(x: "x", y: "y"),
    data: range(0, 101).map(i => (x: i, y: i)),
  ),
  none,
)
#assert.eq(_axis-breaks(trained.x), extended(-5.0, 105.0, m: 5, integer: true))
// The previous `pretty` ladder would have stepped by 20 over this range.
#assert(_axis-breaks(trained.x) != pretty(-5.0, 105.0, n: 5, integer: true))

// --- and is exposed as a helper ---

#assert.eq((breaks-extended())((0, 50, 100)), extended(0, 100, m: 5))
#assert.eq((breaks-extended(n: 8))(()), ())
#let asked = train(
  scales: scales(x: scale-continuous(breaks: breaks-extended(n: 8))),
  layers: (geom-point(),),
  mapping: aes(x: "x", y: "y"),
  data: range(0, 101).map(i => (x: i, y: i)),
)
#assert.eq(asked.x.spec.breaks, extended(0, 100, m: 8, integer: true))
