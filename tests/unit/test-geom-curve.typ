// geom-curve smoke + bezier-sampling tests.

#import "../../src/geom/curve.typ": _curve-points, geom-curve

// Constructor returns a layer dict with the documented defaults.
#let g = geom-curve()
#assert.eq(g.kind, "layer")
#assert.eq(g.name, "curve")
#assert.eq(g.stat, "identity")
#assert.eq(g.position, "identity")
#assert.eq(g.params.curvature, 0.5)
#assert.eq(g.params.angle, 90deg)
#assert.eq(g.params.n, 32)
#assert.eq(g.params.linetype, auto)

// Layer params honour overrides.
#let g2 = geom-curve(curvature: -1, angle: 60deg, n: 64, stroke: 1pt)
#assert.eq(g2.params.curvature, -1)
#assert.eq(g2.params.angle, 60deg)
#assert.eq(g2.params.n, 64)
#assert.eq(g2.params.stroke, 1pt)

// Curve sampling: with curvature: 0 the bezier collapses to the chord, so
// every sample lies on the straight line between endpoints.
#let straight = _curve-points(0, 0, 4, 0, 0, calc.cos(90deg), 4)
#assert.eq(straight.len(), 5)
#assert.eq(straight.at(0), (0, 0))
#assert.eq(straight.at(4), (4, 0))
// Midpoint sample sits on the chord.
#assert.eq(straight.at(2), (2, 0))

// With curvature: 0.5 and a horizontal chord, the apex sits perpendicular
// (above) at half the chord length: midpoint y = 0.5 * length / 2 (the
// bezier apex is half the control-point offset because of the (1-t)t
// weighting at t = 0.5).
#let bowed = _curve-points(0, 0, 4, 0, 0.5, calc.cos(90deg), 4)
#let mid = bowed.at(2)
// Bezier midpoint y = 2 * (1 - 0.5) * 0.5 * cy = 0.5 * cy where cy = 0.5 * 4.
#assert.eq(mid.at(0), 2)
#assert.eq(mid.at(1), 1)

// Negative curvature flips the apex to the other side.
#let bowed-neg = _curve-points(0, 0, 4, 0, -0.5, calc.cos(90deg), 4)
#assert.eq(bowed-neg.at(2).at(1), -1)

// Zero-length chord short-circuits to a single point.
#let degenerate = _curve-points(1, 2, 1, 2, 0.5, calc.cos(90deg), 4)
#assert.eq(degenerate.len(), 1)

geom-curve smoke tests passed.
