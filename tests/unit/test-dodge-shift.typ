// The dodge shift every geom applies, so dodged marks of one group share one
// centre on every coord.
//
// The slot is resolved once per layer by `dodge-geometry` and spent per row by
// `dodge-uv` on the mapped position, so these assert the pair: what the
// geometry answers for a layer, and what a row does with it.

#import "../../src/coord/cartesian.typ": coord-cartesian
#import "../../src/coord/radial.typ": coord-radial
#import "../../src/position/dodge.typ": dodge-geometry, dodge-uv

#let assert-close(a, b, tol: 1e-9) = {
  assert(
    calc.abs(a - b) < tol,
    message: "expected " + repr(a) + " ~= " + repr(b),
  )
}

#let x-trained = (type: "discrete", domain: ("Q1", "Q2"))
#let y-cont = (type: "continuous", domain: (0, 1))
#let ctx = (
  trained: (x: x-trained, y: y-cont),
  px-range: (0, 10),
  py-range: (0, 6),
  coord: coord-cartesian(),
)

#let layer-dodge = (position: "dodge")
#let row-a = (_dodge-offset: -0.25)
#let row-b = (_dodge-offset: 0.25)

// A layer that does not dodge has no geometry, and a row under none stays put.
#assert.eq(dodge-geometry(ctx, (position: "identity")), none)
#assert.eq(dodge-uv(none, row-a, (1.0, 2.0)), (1.0, 2.0))

// Dodge over a discrete x: slot-width 10/2 = 5, width 0.9, so span = 4.5.
// Two groups at the same category shift equal and opposite on x only.
#let geom = dodge-geometry(ctx, layer-dodge)
#assert-close(geom.span, 4.5)
#assert.eq(geom.axis, 0)
#let ua = dodge-uv(geom, row-a, (1.0, 2.0))
#let ub = dodge-uv(geom, row-b, (1.0, 2.0))
#assert-close(ua.at(0), 1.0 - 0.25 * 4.5)
#assert-close(ub.at(0), 1.0 + 0.25 * 4.5)
#assert.eq(ua.at(1), 2.0)

// A row with no dodge offset stays put even on a dodge layer.
#assert.eq(dodge-uv(geom, (:), (1.0, 2.0)), (1.0, 2.0))

// Under coord-radial the span is in the range the coord maps x into. With
// theta on x, two levels split a full turn into slots of pi radians. The sweep
// runs clockwise, so theta falls as x rises and the span is negative: the
// slots follow the level order round the circle.
#let radial-ctx(theta) = {
  let coord = coord-radial(theta: theta)
  ctx + (
    coord: coord,
    radial: (coord.frame)(x-trained, y-cont, (0, 10), (0, 6)),
  )
}
#let theta-geom = dodge-geometry(radial-ctx("x"), layer-dodge)
#assert-close(theta-geom.span, -calc.pi * 0.9)
#assert.eq(theta-geom.axis, 0)

// With theta on y, x takes the radius: the two levels split it into rings.
#let ring-ctx = radial-ctx("y")
#let ring-geom = dodge-geometry(ring-ctx, layer-dodge)
#assert-close(ring-geom.span, ring-ctx.radial.r-max / 2 * 0.9)

// A continuous category axis has no slot width of its own, so the geometry
// infers one from the data: the narrowest canvas gap between two distinct x
// values, scaled by the dodge width. This is the branch that costs a pass over
// every row, which is why it is resolved once per draw rather than per group.
#let cont-x = (type: "continuous", domain: (0, 10))
#let cont-ctx(rows) = (
  trained: (x: cont-x, y: y-cont),
  px-range: (0, 10),
  py-range: (0, 6),
  coord: coord-cartesian(),
  resolve-data: _ => rows,
  resolve-mapping: _ => (x: "x"),
)

// Values 0, 2 and 6 map to 0, 2 and 6 on a 10cm axis, so the narrowest gap is
// 2cm and the span is that gap times the 0.9 default width.
#assert-close(
  dodge-geometry(cont-ctx(((x: 0), (x: 2), (x: 6))), layer-dodge).span,
  2 * 0.9,
)

// One distinct value leaves no gap to measure, so the axis falls back to a
// tenth of its own length.
#assert-close(
  dodge-geometry(cont-ctx(((x: 3), (x: 3))), layer-dodge).span,
  10 / 10 * 0.9,
)

// Without the closures that reach the data there is no way to infer a slot, so
// the layer does not dodge rather than dodging by a guess.
#let ctx-cont = (
  trained: (x: cont-x, y: y-cont),
  px-range: (0, 10),
  py-range: (0, 6),
  coord: coord-cartesian(),
)
#assert.eq(dodge-geometry(ctx-cont, layer-dodge), none)

// Under coord-flip the category axis is y, so the shift lands on v.
#let ctx-flip = (
  trained: (x: y-cont, y: x-trained),
  px-range: (0, 10),
  py-range: (0, 8),
  flipped: true,
  coord: coord-cartesian(),
)
#let flipped-geom = dodge-geometry(ctx-flip, layer-dodge)
#assert.eq(flipped-geom.axis, 1)
#let uf = dodge-uv(flipped-geom, row-a, (1.0, 2.0))
#assert.eq(uf.at(0), 1.0)
#assert-close(uf.at(1), 2.0 - 0.25 * (8 / 2) * 0.9)

// A flipped continuous category axis infers its slot from the category
// column, which the flip swap moved onto y, not from the value column on x.
#let flip-cont-ctx = (
  trained: (x: y-cont, y: cont-x),
  px-range: (0, 6),
  py-range: (0, 10),
  flipped: true,
  coord: coord-cartesian(),
  resolve-data: _ => ((x: 0.5, y: 0), (x: 0.6, y: 2), (x: 0.7, y: 6)),
  resolve-mapping: _ => (x: "x", y: "y"),
)
#assert-close(dodge-geometry(flip-cont-ctx, layer-dodge).span, 2 * 0.9)

// A position dict carries its own width, scaling the span accordingly.
#let dw = dodge-uv(
  dodge-geometry(ctx, (position: (name: "dodge", params: (width: 0.5)))),
  row-a,
  (0.0, 0.0),
)
#assert-close(dw.at(0), -0.25 * 5 * 0.5)

dodge shift tests passed.
