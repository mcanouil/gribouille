// _x-label-depth and _y-label-width compose the measured ink-bbox of the
// longest tick label with the rotation angle. Inputs are cm floats; the
// formulas are pure trigonometry so output is deterministic.

#import "../../src/render/extents.typ": _x-label-depth, _y-label-width

#let approx-eq(a, b, tol: 1e-6) = {
  let diff = a - b
  if diff < 0 { diff = -diff }
  assert(diff < tol, message: "expected " + repr(a) + " ~= " + repr(b))
}

// At angle 0, x-depth equals the label height (no width contribution).
#approx-eq(_x-label-depth(0, 1, 1.0, 0.2), 0.2)
// At angle 90, x-depth equals the label width.
#approx-eq(_x-label-depth(90, 1, 1.0, 0.2), 1.0)
// At angle 30, x-depth is w*sin + h*cos.
#approx-eq(
  _x-label-depth(30, 1, 1.0, 0.2),
  1.0 * calc.sin(30deg) + 0.2 * calc.cos(30deg),
)

// n-dodge > 1 stacks dodge rows at 0.35cm each.
#approx-eq(_x-label-depth(0, 2, 1.0, 0.2), 0.2 + 0.35)

// y-width formula mirrors x-depth with cos/sin swapped at angle 0.
#approx-eq(_y-label-width(0, 1, 1.0, 0.2), 1.0)
#approx-eq(_y-label-width(90, 1, 1.0, 0.2), 0.2)
#approx-eq(
  _y-label-width(30, 1, 1.0, 0.2),
  1.0 * calc.cos(30deg) + 0.2 * calc.sin(30deg),
)

// Tighter than the legacy bbox formula: with a measured ink-height of 0.2cm
// (typical for 8pt digits), the angle-30 depth is < the legacy calculation
// using full line-height (0.282cm) for the same w.
#let measured-depth = _x-label-depth(30, 1, 1.0, 0.2)
#let legacy-depth = 1.0 * calc.sin(30deg) + 0.282 * calc.cos(30deg)
#assert(
  measured-depth < legacy-depth,
  message: "measured depth should be tighter than legacy line-height bbox",
)

rotated label depth smoke test passed.
