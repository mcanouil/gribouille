// guide-axis-logticks() builds a guide spec carrying the logticks flag, and the
// ticks it draws split into a mid and a short tier.

#import "../../src/guide/axis.typ": guide-axis, guide-axis-logticks
#import "../../src/guides.typ": guides
#import "../../src/render/axis-format.typ": (
  LOG10-MID-MANTISSAS, LOG10-SHORT-MANTISSAS, _log10-tier-positions,
)

#let g = guide-axis-logticks()
#assert.eq(g.kind, "guide")
#assert.eq(g.angle, 0)
#assert.eq(g.n-dodge, 1)
#assert.eq(g.logticks, true)

#let g2 = guide-axis-logticks(angle: 45, n-dodge: 2)
#assert.eq(g2.angle, 45)
#assert.eq(g2.n-dodge, 2)
#assert.eq(g2.logticks, true)

// Plain guide-axis omits the flag (defaults to no minor ticks).
#let plain = guide-axis()
#assert.eq(plain.at("logticks", default: false), false)

// Bound to either x or y.
#let bound = guides(
  x: guide-axis-logticks(),
  y: guide-axis-logticks(angle: 30),
)
#assert.eq(bound.x.logticks, true)
#assert.eq(bound.y.angle, 30)

// The two tiers cover 2 to 9 between them and share no position, so every
// sub-decade step carries exactly one tick, at exactly one length.
#assert.eq(
  (LOG10-MID-MANTISSAS + LOG10-SHORT-MANTISSAS).sorted(),
  (2, 3, 4, 5, 6, 7, 8, 9),
)
#assert.eq(_log10-tier-positions(1, 100, LOG10-MID-MANTISSAS), (5.0, 50.0))
#assert.eq(
  (
    _log10-tier-positions(1, 100, LOG10-MID-MANTISSAS)
      + _log10-tier-positions(1, 100, LOG10-SHORT-MANTISSAS)
  ).sorted(),
  _log10-tier-positions(1, 100, (2, 3, 4, 5, 6, 7, 8, 9)),
)

Guide-axis-logticks tests passed.
