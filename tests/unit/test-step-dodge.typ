// `rows-to-points` steps the dodge offsets with the mapped positions, so a
// dodged step line on a cartesian panel keeps the corners it had when each
// point was shifted first and the shifted points were then stepped.

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

// Span 2.5 along (0.6, 0.8) shifts the rows by (0.6, 0.8), (-0.6, -0.8) and
// (0.3, 0.4), to (1.6, 2.8), (3.4, 5.2) and (7.3, 3.4).
#let dodge = (span: 2.5, direction: (0.6, 0.8))

// "hv" puts each corner at the next x and the previous y.
#assert-points(
  rows-to-points(rows, mapping, ctx, dodge, direction: "hv"),
  ((1.6, 2.8), (3.4, 2.8), (3.4, 5.2), (7.3, 5.2), (7.3, 3.4)),
)

// "vh" puts each corner at the previous x and the next y.
#assert-points(
  rows-to-points(rows, mapping, ctx, dodge, direction: "vh"),
  ((1.6, 2.8), (1.6, 5.2), (3.4, 5.2), (3.4, 3.4), (7.3, 3.4)),
)

Step dodge tests passed.
