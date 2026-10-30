// `rows-to-points` shifts each mapped position onto its dodge slot before it
// steps them, so each corner of a dodged step line takes its x from one shifted
// point and its y from the next.

#import "../../src/coord/cartesian.typ": coord-cartesian
#import "../../src/geom/grouped-path.typ": rows-to-points

#let assert-points(got, want) = {
  assert.eq(got.len(), want.len(), message: repr(got))
  for (p, q) in got.zip(want) {
    assert(
      calc.abs(p.at(0) - q.at(0)) < 1e-9 and calc.abs(p.at(1) - q.at(1)) < 1e-9,
      message: "expected " + repr(q) + " ~= " + repr(p),
    )
  }
}

// Domain and range match, so a row maps to the canvas point of its values.
#let ctx = (
  trained: (
    x: (type: "continuous", domain: (0, 10)),
    y: (type: "continuous", domain: (0, 10)),
  ),
  px-range: (0, 10),
  py-range: (0, 10),
  coord: coord-cartesian(),
)
#let mapping = (x: "x", y: "y")
#let rows = (
  (x: 1, y: 2, _dodge-offset: 0.4),
  (x: 4, y: 6, _dodge-offset: -0.4),
  (x: 7, y: 3, _dodge-offset: 0.2),
)

// Span 2.5 on u shifts the rows by 1, -1 and 0.5 along x, to (2, 2), (3, 6)
// and (7.5, 3).
#let dodge = (span: 2.5, axis: 0)

// "hv" puts each corner at the next x and the previous y.
#assert-points(
  rows-to-points(rows, mapping, ctx, dodge, direction: "hv"),
  ((2, 2), (3, 2), (3, 6), (7.5, 6), (7.5, 3)),
)

// "vh" puts each corner at the previous x and the next y.
#assert-points(
  rows-to-points(rows, mapping, ctx, dodge, direction: "vh"),
  ((2, 2), (2, 6), (3, 6), (3, 3), (7.5, 3)),
)

Step dodge tests passed.
