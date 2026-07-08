// geom-mark smoke + convex hull tests.

#import "../../src/geom/mark.typ": (
  _bbox, _convex-hull, _ellipse-vertices, _expand-hull, _rect-vertices,
  geom-mark,
)

// Constructor returns a layer dict with the documented defaults.
#let g = geom-mark()
#assert.eq(g.kind, "layer")
#assert.eq(g.name, "mark")
#assert.eq(g.stat, "identity")
#assert.eq(g.position, "identity")
#assert.eq(g.params.method, "circle")
#assert.eq(g.params.expand, 0pt)
#assert.eq(g.params.n, 64)
#assert.eq(g.params.alpha, auto)

// Each documented method is accepted.
#assert.eq(geom-mark(method: "rect").params.method, "rect")
#assert.eq(geom-mark(method: "ellipse").params.method, "ellipse")
#assert.eq(geom-mark(method: "hull").params.method, "hull")

// Length expand passes through.
#assert.eq(geom-mark(expand: 5pt).params.expand, 5pt)

// Bbox of a five-point cluster.
#let pts = ((0, 0), (1, 0), (0, 1), (1, 1), (0.5, 0.5))
#let bb = _bbox(pts)
#assert.eq(bb.x-min, 0)
#assert.eq(bb.x-max, 1)
#assert.eq(bb.y-min, 0)
#assert.eq(bb.y-max, 1)

// Rect vertices order: bottom-left, bottom-right, top-right, top-left.
#let r = _rect-vertices(bb, 0.0)
#assert.eq(r, ((0, 0), (1, 0), (1, 1), (0, 1)))

// Expand pads the bbox uniformly.
#let r2 = _rect-vertices(bb, 0.5)
#assert.eq(r2, ((-0.5, -0.5), (1.5, -0.5), (1.5, 1.5), (-0.5, 1.5)))

// Convex hull drops interior points and traces the boundary CCW.
#let hull = _convex-hull(pts)
#assert.eq(hull.len(), 4)
#assert(hull.contains((0, 0)))
#assert(hull.contains((1, 0)))
#assert(hull.contains((1, 1)))
#assert(hull.contains((0, 1)))
#assert(not hull.contains((0.5, 0.5)))

// Hull on collinear / near-zero points returns the input unchanged.
#assert.eq(_convex-hull(((0, 0),)), ((0, 0),))
#assert.eq(_convex-hull(((0, 0), (1, 1))), ((0, 0), (1, 1)))

// Expanding a hull pushes vertices radially outward; a unit square hull at
// the origin grows in both axes when expand > 0.
#let unit-hull = ((0, 0), (1, 0), (1, 1), (0, 1))
#let expanded = _expand-hull(unit-hull, 0.2)
#assert(expanded.at(0).at(0) < 0)
#assert(expanded.at(0).at(1) < 0)
#assert(expanded.at(2).at(0) > 1)
#assert(expanded.at(2).at(1) > 1)

// Ellipse vertices ride a closed parametric loop with semi-axes from bbox.
#let ev = _ellipse-vertices(bb, 0.0, 8)
#assert.eq(ev.len(), 8)
// First sample (t=0) sits on the right edge of the bbox.
#assert.eq(ev.at(0), (1, 0.5))

geom-mark smoke tests passed.
