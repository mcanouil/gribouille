// The dodge shift the project-point geoms apply (point, line, path,
// text/label/typst, point/linerange) so dodged marks ride the same slots the
// bar geoms compute from their band math.
//
// The slot is resolved once per layer by `dodge-geometry` and spent per row by
// `dodge-delta`, so these assert the pair: what the geometry answers for a
// layer, and what a row does with it.

#import "../../src/position/dodge.typ": dodge-delta, dodge-geometry

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
)

#let layer-dodge = (position: "dodge")
#let row-a = (_dodge-offset: -0.25)
#let row-b = (_dodge-offset: 0.25)

// A layer that does not dodge has no geometry, and a row under none stays put.
#assert.eq(dodge-geometry(ctx, (position: "identity")), none)
#assert.eq(dodge-delta(none, row-a), (0.0, 0.0))

// Dodge over a discrete x: slot-width 10/2 = 5, width 0.9, so span = 4.5.
// Two groups at the same category shift equal and opposite on x only.
#let geom = dodge-geometry(ctx, layer-dodge)
#assert-close(geom.span, 4.5)
#assert.eq(geom.flipped, false)
#let da = dodge-delta(geom, row-a)
#let db = dodge-delta(geom, row-b)
#assert-close(da.at(0), -0.25 * 4.5)
#assert-close(db.at(0), 0.25 * 4.5)
#assert.eq(da.at(1), 0.0)
#assert-close(da.at(0), -db.at(0))

// A row with no dodge offset stays put even on a dodge layer.
#assert.eq(dodge-delta(geom, (:)), (0.0, 0.0))

// Radial coordinates: dodge does not apply on the angular axis.
#assert.eq(dodge-geometry(ctx + (radial: true), layer-dodge), none)

// Continuous category axis is out of scope for this helper.
#let ctx-cont = (
  trained: (x: (type: "continuous", domain: (0, 10)), y: y-cont),
  px-range: (0, 10),
  py-range: (0, 6),
)
#assert.eq(dodge-geometry(ctx-cont, layer-dodge), none)

// Under coord-flip the category axis is y, so the shift lands on y.
#let ctx-flip = (
  trained: (x: y-cont, y: x-trained),
  px-range: (0, 10),
  py-range: (0, 8),
  flipped: true,
)
#let flipped-geom = dodge-geometry(ctx-flip, layer-dodge)
#assert.eq(flipped-geom.flipped, true)
#let df = dodge-delta(flipped-geom, row-a)
#assert.eq(df.at(0), 0.0)
#assert-close(df.at(1), -0.25 * (8 / 2) * 0.9)

// A position dict carries its own width, scaling the span accordingly.
#let dw = dodge-delta(
  dodge-geometry(ctx, (position: (name: "dodge", params: (width: 0.5)))),
  row-a,
)
#assert-close(dw.at(0), -0.25 * 5 * 0.5)

dodge-delta tests passed.
