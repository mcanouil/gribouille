// dodge-delta: canvas-cm shift applied by the project-point geoms (point,
// line, path, text/label/typst, point/linerange) so dodged marks ride the
// same slots the bar geoms compute from their band math.

#import "../../src/position/dodge.typ": dodge-delta

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

// Non-dodge layer: no shift.
#assert.eq(dodge-delta(ctx, (position: "identity"), row-a), (0.0, 0.0))

// Dodge over a discrete x: slot-width 10/2 = 5, width 0.9, so span = 4.5.
// Two groups at the same category shift equal and opposite on x only.
#let da = dodge-delta(ctx, layer-dodge, row-a)
#let db = dodge-delta(ctx, layer-dodge, row-b)
#assert-close(da.at(0), -0.25 * 4.5)
#assert-close(db.at(0), 0.25 * 4.5)
#assert.eq(da.at(1), 0.0)
#assert-close(da.at(0), -db.at(0))

// A row with no dodge offset stays put even on a dodge layer.
#assert.eq(dodge-delta(ctx, layer-dodge, (:)), (0.0, 0.0))

// Radial coordinates: dodge does not apply on the angular axis.
#assert.eq(dodge-delta(ctx + (radial: true), layer-dodge, row-a), (0.0, 0.0))

// Continuous category axis is out of scope for this helper.
#let ctx-cont = (
  trained: (x: (type: "continuous", domain: (0, 10)), y: y-cont),
  px-range: (0, 10),
  py-range: (0, 6),
)
#assert.eq(dodge-delta(ctx-cont, layer-dodge, row-a), (0.0, 0.0))

// Under coord-flip the category axis is y, so the shift lands on y.
#let ctx-flip = (
  trained: (x: y-cont, y: x-trained),
  px-range: (0, 10),
  py-range: (0, 8),
  flipped: true,
)
#let df = dodge-delta(ctx-flip, layer-dodge, row-a)
#assert.eq(df.at(0), 0.0)
#assert-close(df.at(1), -0.25 * (8 / 2) * 0.9)

// A position dict carries its own width, scaling the span accordingly.
#let dw = dodge-delta(
  ctx,
  (position: (name: "dodge", params: (width: 0.5))),
  row-a,
)
#assert-close(dw.at(0), -0.25 * 5 * 0.5)

dodge-delta tests passed.
