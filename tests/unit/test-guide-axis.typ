// guide-axis() builds a spec consumed by both x and y axes.

#import "../../src/guide/axis.typ": guide-axis
#import "../../src/guides.typ": guides
#import "../../src/render/guides.typ": _read-axis-guide

#let g = guide-axis()
#assert.eq(g.kind, "guide")
#assert.eq(g.angle, 0)
#assert.eq(g.n-dodge, 1)

#let g2 = guide-axis(angle: 30, n-dodge: 2)
#assert.eq(g2.angle, 30)
#assert.eq(g2.n-dodge, 2)

// Bound to either x or y; renderer reads the same shape.
#let bound = guides(x: guide-axis(angle: 45), y: guide-axis(n-dodge: 2))
#assert.eq(bound.x.angle, 45)
#assert.eq(bound.y.n-dodge, 2)

// `guides(x: none)` binds the suppress marker; `_read-axis-guide` carries it
// through as `suppress: true` so the renderer hides that axis. A real guide and
// an absent guide both read as `suppress: false`.
#assert.eq(_read-axis-guide((guides: guides(x: none)), "x").suppress, true)
#assert.eq(
  _read-axis-guide((guides: guides(x: guide-axis(angle: 45))), "x").suppress,
  false,
)
#assert.eq(_read-axis-guide((:), "x").suppress, false)

Guide-axis tests passed.
