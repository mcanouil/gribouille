// _title-angle resolves an element-text rotation, falling back to the axis's
// natural default. _title-extent-cm reserves the perpendicular space for a
// title rotated by that angle, keeping the natural angle at one line height.

#import "../../src/render/extents.typ": (
  _ax-text-cm, _title-angle, _title-extent-cm,
)

#let approx-eq(a, b, tol: 1e-6) = {
  let diff = a - b
  if diff < 0 { diff = -diff }
  assert(diff < tol, message: "expected " + repr(a) + " ~= " + repr(b))
}

// Unset angle falls back to the supplied default.
#assert.eq(_title-angle((angle: none), 0), 0deg)
#assert.eq(_title-angle((angle: none), 90), 90deg)
// An explicit angle wins over the default, including the reported -90deg case.
#assert.eq(_title-angle((angle: -90deg), 90), -90deg)
#assert.eq(_title-angle((angle: 45deg), 0), 45deg)

#let style = (angle: none, size: 9pt)
#let line-h = _ax-text-cm(9pt)
#let ext = (width: 5.0, height: 0.3)

// At its natural angle a title reserves exactly one line height, so width is
// irrelevant: x titles read horizontally (0deg), y titles vertically (90deg).
#approx-eq(_title-extent-cm(style, ext, "x"), line-h)
#approx-eq(_title-extent-cm(style, ext, "y"), line-h)

// A horizontal y title (0deg) reserves the full measured title width beside
// the panel; a vertical x title (90deg) reserves it below.
#approx-eq(_title-extent-cm((angle: 0deg, size: 9pt), ext, "y"), 5.0)
#approx-eq(_title-extent-cm((angle: 90deg, size: 9pt), ext, "x"), 5.0)

// At 45deg both the width and the line height contribute.
#approx-eq(
  _title-extent-cm((angle: 45deg, size: 9pt), ext, "x"),
  5.0 * calc.sin(45deg) + line-h * calc.cos(45deg),
)

// Unmeasured extents (no title) collapse to the line-height term only.
#approx-eq(_title-extent-cm(style, none, "x"), line-h)

title angle smoke test passed.
