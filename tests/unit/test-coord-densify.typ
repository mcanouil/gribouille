// `project-path` joins mapped points through the coord's `densify`: a linear
// coord keeps the points of `project-point`, and `coord-radial` breaks every
// edge that sweeps five degrees or more of theta into `arc-steps` chords.

#import "../../src/coord/cartesian.typ": coord-cartesian
#import "../../src/coord/radial.typ": coord-radial
#import "../../src/coord/project.typ": project-path, project-point
#import "../../src/utils/radial.typ": arc-steps

#let tx = (type: "continuous", domain: (0, 360))
#let ty = (type: "continuous", domain: (0, 10))
#let px-range = (0, 6)
#let py-range = (0, 6)

#let ctx = (
  trained: (x: tx, y: ty),
  px-range: px-range,
  py-range: py-range,
  coord: coord-cartesian(),
)

#let pairs = ((0, 1), (90, 5), (180, 2))
#assert.eq(
  project-path(ctx, pairs),
  pairs.map(((xv, yv)) => project-point(ctx, xv, yv)),
)
#assert.eq(project-path(ctx, pairs, closed: true).len(), 3)

// A pair that maps to `none` is dropped and joins nothing.
#assert.eq(
  project-path(ctx, ((0, 1), (none, 5), (180, 2))),
  (project-point(ctx, 0, 1), project-point(ctx, 180, 2)),
)

#let radial-coord = coord-radial()
#let radial-ctx = (
  ctx
    + (
      coord: radial-coord,
      radial: (radial-coord.frame)(tx, ty, px-range, py-range),
    )
)

// A quarter turn at constant y is an arc: every point sits at one radius.
#let arc = project-path(radial-ctx, ((0, 5), (90, 5)))
#assert.eq(arc.len(), arc-steps(calc.pi / 2) + 1)
#assert.eq(arc.first(), project-point(radial-ctx, 0, 5))
#assert.eq(arc.last(), project-point(radial-ctx, 90, 5))
#let (ox, oy) = radial-ctx.radial.centre
#let radius(p) = calc.sqrt(
  calc.pow(p.at(0) - ox, 2) + calc.pow(p.at(1) - oy, 2),
)
#for p in arc {
  assert(calc.abs(radius(p) - radius(arc.first())) < 1e-9)
}

// With `theta: "y"` the sweep runs along y: an edge that moves y at constant x
// is an arc, and an edge that moves x at constant y is one radial chord.
#let y-coord = coord-radial(theta: "y")
#let y-ctx = (
  ctx
    + (
      coord: y-coord,
      radial: (y-coord.frame)(tx, ty, px-range, py-range),
    )
)
#assert(project-path(y-ctx, ((180, 0), (180, 10))).len() > 2)
#assert.eq(project-path(y-ctx, ((0, 5), (360, 5))).len(), 2)

// An edge under five degrees stays one chord.
#assert.eq(project-path(radial-ctx, ((0, 5), (2, 5))).len(), 2)

// `closed: true` densifies the edge from the last point back to the first.
#let ring = ((0, 5), (90, 5), (180, 5))
#assert.eq(
  project-path(radial-ctx, ring).len(),
  2 * arc-steps(calc.pi / 2) + 1,
)
#assert.eq(
  project-path(radial-ctx, ring, closed: true).len(),
  2 * arc-steps(calc.pi / 2) + arc-steps(calc.pi),
)
