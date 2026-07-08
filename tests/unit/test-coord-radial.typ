// coord-radial: spec dictionary shape and core projection helpers.

#import "../../src/coord/radial.typ": coord-radial
#import "../../src/utils/radial.typ": (
  group-theta-breaks, radial-ctx, radial-point, radial-r, radial-theta,
  radial-wedge,
)

#let approx-eq(a, b, eps: 1e-6) = calc.abs(a - b) < eps

#let c = coord-radial()
#assert.eq(c.kind, "coord")
#assert.eq(c.name, "radial")
#assert.eq(c.theta, "x")
#assert.eq(c.start, 0)
#assert.eq(c.direction, 1)

#let c2 = coord-radial(theta: "y", start: 0.5, direction: -1)
#assert.eq(c2.theta, "y")
#assert.eq(c2.start, 0.5)
#assert.eq(c2.direction, -1)

// Trained continuous scale stub: x in [0, 4], y in [0, 100].
#let cont-trained(domain) = (
  type: "continuous",
  domain: domain,
)

#let xt = cont-trained((0, 4))
#let yt = cont-trained((0, 100))
#let radial = radial-ctx(c, xt, yt, (0, 10), (0, 10))
#assert(radial != none)
#assert.eq(radial.centre, (5, 5))
#assert.eq(radial.r-max, 5)
#assert.eq(radial.theta-axis, "x")
#assert.eq(radial.r-range, (0, 5))

// Cartesian and other coords return `none`.
#assert.eq(radial-ctx(none, xt, yt, (0, 10), (0, 10)), none)
#assert.eq(
  radial-ctx(
    (kind: "coord", coord: "cartesian"),
    xt,
    yt,
    (0, 10),
    (0, 10),
  ),
  none,
)

// theta sweep runs from π/2 (12 o'clock) clockwise back to -3π/2 by default.
#assert(approx-eq(radial.theta-range.at(0), calc.pi / 2))
#assert(approx-eq(radial.theta-range.at(1), calc.pi / 2 - 2 * calc.pi))

// Cardinal angular positions for theta = "x" (x is angular).
// x = 0 → 12 o'clock; x = 1 (quarter sweep) → 3 o'clock; x = 2 → 6 o'clock.
#let p0 = radial-point(0, 50, radial)
#assert(approx-eq(p0.at(0), 5))
#assert(approx-eq(p0.at(1), 5 + 2.5))
#let p-quarter = radial-point(1, 50, radial)
#assert(approx-eq(p-quarter.at(0), 5 + 2.5))
#assert(approx-eq(p-quarter.at(1), 5))
#let p-half = radial-point(2, 50, radial)
#assert(approx-eq(p-half.at(0), 5))
#assert(approx-eq(p-half.at(1), 5 - 2.5))

// theta = "y" swaps which scale is angular vs radial. Pie-style projection:
// y is angular, x is radial. y = 0 → 12 o'clock at full r when x = 4.
#let pie-coord = coord-radial(theta: "y")
#let pie = radial-ctx(pie-coord, xt, yt, (0, 10), (0, 10))
#assert.eq(pie.theta-axis, "y")
#let pie-top = radial-point(4, 0, pie)
#assert(approx-eq(pie-top.at(0), 5))
#assert(approx-eq(pie-top.at(1), 5 + 5))
#let pie-bottom = radial-point(4, 50, pie)
#assert(approx-eq(pie-bottom.at(0), 5))
#assert(approx-eq(pie-bottom.at(1), 5 - 5))

// Wedge vertex count: outer arc has `steps + 1` points; closed at the centre
// when r-lo is 0, so total = steps + 2.
#let wedge = radial-wedge(0, calc.pi / 2, 0, 5, radial, n: 8)
#assert.eq(wedge.len(), 8 + 2)

// Annular wedge: both arcs sampled, total = 2 * (steps + 1).
#let annulus = radial-wedge(0, calc.pi / 2, 2, 5, radial, n: 8)
#assert.eq(annulus.len(), 2 * (8 + 1))

// direction = -1 inverts the sweep: x = 1 (quarter sweep) lands at 9 o'clock.
#let ccw-coord = coord-radial(direction: -1)
#let ccw = radial-ctx(ccw-coord, xt, yt, (0, 10), (0, 10))
#let ccw-quarter = radial-point(1, 50, ccw)
#assert(approx-eq(ccw-quarter.at(0), 5 - 2.5))
#assert(approx-eq(ccw-quarter.at(1), 5))

// start rotates the sweep origin: start = π/2 puts x = 0 at 3 o'clock.
#let off-coord = coord-radial(start: calc.pi / 2)
#let off = radial-ctx(off-coord, xt, yt, (0, 10), (0, 10))
#let off-zero = radial-point(0, 50, off)
#assert(approx-eq(off-zero.at(0), 5 + 2.5))
#assert(approx-eq(off-zero.at(1), 5))

// `end: none` means a full sweep in the requested direction (default).
#assert.eq(coord-radial().end, none)

// Explicit `end` overrides the full-sweep default. end = π yields a half
// circle: theta-lo at 12 o'clock, theta-hi at 6 o'clock.
#let half-coord = coord-radial(end: calc.pi)
#assert.eq(half-coord.end, calc.pi)
#let half = radial-ctx(half-coord, xt, yt, (0, 10), (0, 10))
#assert(approx-eq(half.theta-range.at(0), calc.pi / 2))
#assert(approx-eq(half.theta-range.at(1), -calc.pi / 2))
// On a half sweep, x = 4 (the domain end) sits at 6 o'clock, not back at 12.
#let half-end = radial-point(4, 50, half)
#assert(approx-eq(half-end.at(0), 5))
#assert(approx-eq(half-end.at(1), 5 - 2.5))

// direction = -1 with `end: none` sweeps counter-clockwise a full turn.
#let ccw-full = radial-ctx(
  coord-radial(direction: -1),
  xt,
  yt,
  (0, 10),
  (0, 10),
)
#assert(approx-eq(ccw-full.theta-range.at(1), calc.pi / 2 + 2 * calc.pi))

// Cyclic-wrap merge: full-sweep domain endpoints share a canvas angle, so
// `group-theta-breaks` collapses them into a single group with both records.
// 24-hour clock: domain (0, 24); both ends sit at 12 o'clock.
#let clock = radial-ctx(
  coord-radial(),
  cont-trained((0, 24)),
  cont-trained((0, 100)),
  (0, 10),
  (0, 10),
)
#let project-clock(b) = radial-theta(b, clock)
#let clock-groups = group-theta-breaks((0, 6, 12, 18, 24), project-clock)
// Five inputs collapse to four unique angles (0 and 24 share 12 o'clock).
#assert.eq(clock-groups.len(), 4)
// The wrap group contains both endpoint records, in enumeration order.
#let wrap = clock-groups.first()
#assert.eq(wrap.len(), 2)
#assert.eq(wrap.at(0).b, 0)
#assert.eq(wrap.at(1).b, 24)

// Distinct angles produce singleton groups.
#let half-coord-end = coord-radial(end: calc.pi)
#let half-bundle = radial-ctx(
  half-coord-end,
  cont-trained((0, 12)),
  cont-trained((0, 100)),
  (0, 10),
  (0, 10),
)
#let half-groups = group-theta-breaks(
  (0, 6, 12),
  b => radial-theta(b, half-bundle),
)
#assert.eq(half-groups.len(), 3)
#assert(half-groups.all(g => g.len() == 1))

// clip defaults to false (no clipping); true surfaces on the bundle as `true`.
#let clip-default = coord-radial()
#assert.eq(clip-default.clip, false)
#let clip-on = coord-radial(clip: true)
#assert.eq(clip-on.clip, true)
#let clip-default-bundle = radial-ctx(clip-default, xt, yt, (0, 10), (0, 10))
#assert.eq(clip-default-bundle.clip, false)
#let clip-on-bundle = radial-ctx(clip-on, xt, yt, (0, 10), (0, 10))
#assert.eq(clip-on-bundle.clip, true)

coord-radial tests passed.
