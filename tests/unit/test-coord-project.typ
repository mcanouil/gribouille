// Projection routed through the coord: `project-point`, `axis-mapper`, and
// `to-canvas` give the same canvas points the trained scales and the radial
// bundle gave before the coord carried them.

#import "../../src/coord/cartesian.typ": coord-cartesian
#import "../../src/coord/radial.typ": coord-radial
#import "../../src/coord/project.typ": axis-mapper, project-point, to-canvas
#import "../../src/scale/train.typ": map-axis, map-position
#import "../../src/utils/radial.typ": radial-point

#let tx = (type: "continuous", domain: (0, 10))
#let ty = (type: "discrete", domain: ("a", "b"))
#let px-range = (0, 5)
#let py-range = (0, 3)

#let ctx = (
  trained: (x: tx, y: ty),
  px-range: px-range,
  py-range: py-range,
  coord: coord-cartesian(),
)

#let cx = map-position(tx, 5, px-range)
#let cy = map-position(ty, "b", py-range)
#assert.eq(project-point(ctx, 5, "b"), (cx, cy))
#assert.eq(axis-mapper(ctx, "x")(5), cx)
#assert.eq(axis-mapper(ctx, "y")("b"), cy)
#assert.eq(axis-mapper(ctx, "x", space: "stat")(5), map-axis(tx, 5, px-range))
#assert.eq(to-canvas(ctx, cx, cy), (cx, cy))

// An unresolved value on either axis drops the point.
#assert.eq(project-point(ctx, 5, "z"), none)
#assert.eq(axis-mapper(ctx, "y")("z"), none)

// The cartesian frame carries no radial bundle.
#assert.eq((ctx.coord.frame)(tx, ty, px-range, py-range), none)

#let radial-coord = coord-radial()
#let radial-ctx = (
  ctx
    + (
      coord: radial-coord,
      radial: (radial-coord.frame)(tx, ty, px-range, py-range),
    )
)
#let expected = radial-point(5, "b", radial-ctx.radial)
#assert(expected != none)
#assert.eq(project-point(radial-ctx, 5, "b"), expected)
#assert.eq(
  to-canvas(
    radial-ctx,
    axis-mapper(radial-ctx, "x")(5),
    axis-mapper(radial-ctx, "y")("b"),
  ),
  expected,
)

// Under `theta: "y"` the angle comes from y, so `to-canvas` swaps its pair.
#let pie-coord = coord-radial(theta: "y")
#let pie-ctx = (
  (trained: (x: ty, y: tx), px-range: px-range, py-range: py-range)
    + (
      coord: pie-coord,
      radial: (pie-coord.frame)(ty, tx, px-range, py-range),
    )
)
#let pie-expected = radial-point("b", 5, pie-ctx.radial)
#assert.eq(project-point(pie-ctx, "b", 5), pie-expected)
#assert.eq(
  to-canvas(
    pie-ctx,
    axis-mapper(pie-ctx, "x")("b"),
    axis-mapper(pie-ctx, "y")(5),
  ),
  pie-expected,
)
