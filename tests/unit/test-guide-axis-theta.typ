// guide-axis-theta() builds a spec consumed by the radial theta axis.

#import "../../src/guide/axis-theta.typ": guide-axis-theta
#import "../../src/guides.typ": guides
#import "../../src/render/guides.typ": _read-r-guide, _read-theta-guide

#let g = guide-axis-theta()
#assert.eq(g.kind, "guide")
#assert.eq(g.aesthetic, "theta")
#assert.eq(g.angle, 0)
#assert.eq(g.minor-ticks, false)
#assert.eq(g.cap, "none")

#let g2 = guide-axis-theta(angle: 30, minor-ticks: true, cap: "both")
#assert.eq(g2.angle, 30)
#assert.eq(g2.minor-ticks, true)
#assert.eq(g2.cap, "both")

#let bound = guides(theta: guide-axis-theta(angle: 45, cap: "upper"))
#assert.eq(bound.theta.angle, 45)
#assert.eq(bound.theta.cap, "upper")

// `guides(theta: none)` reads as a suppressed theta guide; a real guide reads
// `suppress: false`, and an absent theta key stays `none` (spoke-only).
#assert.eq(_read-theta-guide((guides: guides(theta: none))).suppress, true)
#assert.eq(
  _read-theta-guide((guides: guides(theta: guide-axis-theta()))).suppress,
  false,
)
#assert.eq(_read-theta-guide((:)), none)

// `guides(r: none)` suppresses the radial axis; an absent r key does not.
#assert.eq(_read-r-guide((guides: guides(r: none))).suppress, true)
#assert.eq(_read-r-guide((:)).suppress, false)

Guide-axis-theta tests passed.
