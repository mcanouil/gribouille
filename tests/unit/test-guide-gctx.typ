// The guide context: side geometry, the along/across flip, and the `place`
// closures a guide part maps positions through.

#import "../../src/guide/gctx.typ": (
  DIRECTIONS, POSITIONS, SIDES, _axes-of, _mode-of, direction-for, gctx,
  place-cartesian, place-r, place-theta, pt,
)
#import "../../src/utils/radial.typ": polar-canvas

#assert.eq(SIDES, ("top", "right", "bottom", "left"))
#assert.eq(DIRECTIONS, ("horizontal", "vertical"))
#assert(POSITIONS.contains("theta") and POSITIONS.contains("r"))

// Each side names its reading axis, its thickness axis, and the way it grows
// away from the panel.
#assert.eq(_axes-of("bottom"), (along: "x", across: "y", sign: -1))
#assert.eq(_axes-of("top"), (along: "x", across: "y", sign: 1))
#assert.eq(_axes-of("left"), (along: "y", across: "x", sign: -1))
#assert.eq(_axes-of("right"), (along: "y", across: "x", sign: 1))

// The flip is what lets one horizontal routine serve all four sides.
#assert.eq(pt(_axes-of("bottom"), 3.0, 0.5), (3.0, 0.5))
#assert.eq(pt(_axes-of("left"), 3.0, 0.5), (0.5, 3.0))

// Context comes from the aesthetic, never from the side.
#assert.eq(_mode-of("x"), "axis")
#assert.eq(_mode-of("y"), "axis")
#assert.eq(_mode-of("theta"), "axis")
#assert.eq(_mode-of("r"), "axis")
#assert.eq(_mode-of("colour"), "legend")
#assert.eq(_mode-of("size"), "legend")

#assert.eq(direction-for("top"), "horizontal")
#assert.eq(direction-for("bottom"), "horizontal")
#assert.eq(direction-for("left"), "vertical")
#assert.eq(direction-for("right"), "vertical")

// A bottom axis over the panel x span 2..7 and y span 1..5. `frac` 0.5 lands
// halfway along x, and `across` 0.1 drops 0.1cm below the bottom edge.
#let bottom = place-cartesian("bottom", (2.0, 7.0), (1.0, 5.0))
#assert.eq(bottom(0.5, 0.1), (4.5, 0.9))
#assert.eq(bottom(0.0, 0.0), (2.0, 1.0))
#assert.eq(bottom(1.0, 0.0), (7.0, 1.0))

// The top edge grows upward from y 5.
#let top = place-cartesian("top", (2.0, 7.0), (1.0, 5.0))
#assert.eq(top(0.0, 0.1), (2.0, 5.1))

// A left axis reads along y and grows leftward from x 2.
#let left = place-cartesian("left", (2.0, 7.0), (1.0, 5.0))
#assert.eq(left(0.5, 0.1), (1.9, 3.0))
#assert.eq(left(0.0, 0.0), (2.0, 1.0))

#let right = place-cartesian("right", (2.0, 7.0), (1.0, 5.0))
#assert.eq(right(0.5, 0.1), (7.1, 3.0))

// The radial closures are pinned against `polar-canvas` itself, so the test
// asserts agreement with the projection rather than re-deriving trigonometry.
#let radial = (
  centre: (5.0, 5.0),
  r-max: 3.0,
  theta-range: (0rad, 1.5707963267948966rad),
)

#let theta = place-theta(radial)
#assert.eq(theta(0.0, 0.0), polar-canvas(radial, 0rad, 3.0))
#assert.eq(theta(1.0, 0.0), polar-canvas(radial, 1.5707963267948966rad, 3.0))
// `across` pushes a theta tick outward past the arc.
#assert.eq(theta(0.0, 0.2), polar-canvas(radial, 0rad, 3.2))

// The radius runs from the centre outward, and ignores `across`, because an r
// label sits on the radius rather than offset from it.
#let r = place-r(radial)
#assert.eq(r(0.0, 0.0), polar-canvas(radial, 0rad, 0.0))
#assert.eq(r(1.0, 0.0), polar-canvas(radial, 0rad, 3.0))
#assert.eq(r(0.5, 0.9), r(0.5, 0.0))

// A context resolves its direction and its axis, and carries the closures the
// downstream stages inject.
#let axis-ctx = gctx("bottom", "x", place: bottom, tick-length: _ => 0.1)
#assert.eq(axis-ctx.mode, "axis")
#assert.eq(axis-ctx.direction, "horizontal")
#assert.eq(axis-ctx.axis, "x")
#assert.eq(axis-ctx.tick-gap, 0.1)
#assert.eq((axis-ctx.place)(0.5, 0.1), (4.5, 0.9))

#let legend-ctx = gctx("right", "colour")
#assert.eq(legend-ctx.mode, "legend")
#assert.eq(legend-ctx.direction, "vertical")
#assert.eq(legend-ctx.axis, "y")

// A horizontal colour bar sits on the right of nothing in particular: the side
// does not fix the orientation, so the guide states it.
#assert.eq(
  gctx("right", "colour", direction: "horizontal").direction,
  "horizontal",
)

// A radial context takes its axis from the sweep, since the position cannot
// imply one.
#let theta-ctx = gctx("theta", "theta", axis: "y", place: theta)
#assert.eq(theta-ctx.axis, "y")
#assert.eq(theta-ctx.mode, "axis")

Guide-gctx tests passed.
