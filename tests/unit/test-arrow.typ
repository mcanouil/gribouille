// arrow() spec + head-geometry tests.

#import "../../src/utils/arrow.typ": _arrow-head-points, _direction-point, arrow

#let approx-eq(a, b, eps: 1e-9) = calc.abs(a - b) < eps

// Constructor returns the documented defaults.
#let a = arrow()
#assert.eq(a.kind, "arrow")
#assert.eq(a.length, 4pt)
#assert.eq(a.angle, 25deg)
#assert.eq(a.ends, "last")
#assert.eq(a.type, "open")

// Every field is overridable.
#let a2 = arrow(length: 10pt, angle: 40deg, ends: "both", type: "closed")
#assert.eq(a2.length, 10pt)
#assert.eq(a2.angle, 40deg)
#assert.eq(a2.ends, "both")
#assert.eq(a2.type, "closed")

// A head on a horizontal chord opens symmetrically about the chord: both
// wings sit at the same x, mirrored in y.
#let (left, right) = _arrow-head-points((0, 0), (1, 0), 1, 45deg)
#assert(approx-eq(left.at(0), calc.cos(45deg)))
#assert(approx-eq(right.at(0), calc.cos(45deg)))
#assert(approx-eq(left.at(1), calc.sin(45deg)))
#assert(approx-eq(right.at(1), -calc.sin(45deg)))

// The wings sit `length` from the tip, whatever the chord length.
#let (far, _) = _arrow-head-points((0, 0), (37, 0), 0.5, 25deg)
#assert(approx-eq(
  calc.sqrt(far.at(0) * far.at(0) + far.at(1) * far.at(1)),
  0.5,
))

// Reversing the chord mirrors the head through the tip.
#let (back-left, back-right) = _arrow-head-points((0, 0), (-1, 0), 1, 45deg)
#assert(approx-eq(back-left.at(0), -calc.cos(45deg)))
#assert(approx-eq(back-right.at(0), -calc.cos(45deg)))

// A zero-length chord leaves no direction to point along.
#assert.eq(_arrow-head-points((2, 3), (2, 3), 1, 25deg), none)

// The direction point skips neighbours that coincide with the anchor, so a
// sampled curve whose last samples repeat still finds its tangent.
#let pts = ((0, 0), (1, 1), (2, 2), (2, 2))
#assert.eq(_direction-point(pts, 3, -1), (1, 1))
#assert.eq(_direction-point(pts, 0, 1), (1, 1))

// Every point coinciding leaves no direction at all.
#assert.eq(_direction-point(((5, 5), (5, 5)), 1, -1), none)

arrow smoke tests passed.
