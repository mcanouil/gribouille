// Inside-panel legend background: `_inside-anchor` places the guide bbox so
// the painted `legend-background` -- the bbox grown by `pad` (inset), plus
// the `gap` (outset) reserved around it -- stays within `panel-rect` instead
// of overflowing an edge-flush alignment. `_bg-metrics` resolves that pad /
// gap once and gates `pad` on the rect actually painting, so an unthemed
// legend (no fill or stroke) keeps today's anchor exactly.

#import "../../src/render/legend.typ": _bg-edge-cm, _bg-metrics, _inside-anchor
#import "../../src/theme/defaults.typ": merge-theme
#import "../../lib.typ": element-rect, margin, theme

#let approx-eq(a, b, tol: 1e-9) = {
  let diff = a - b
  if diff < 0 { diff = -diff }
  assert(diff < tol, message: "expected " + repr(a) + " ~= " + repr(b))
}

#let zero-edge = (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0)
#let panel-rect = (x: 1.0, y: 2.0, w: 8.0, h: 5.0)
#let w = 2.0
#let h = 1.0

// Zero edge (no themed background) reproduces the current content-box-only
// anchor for every alignment.
#assert.eq(_inside-anchor(panel-rect, w, h, right, top, zero-edge).x, 7.0)
#assert.eq(_inside-anchor(panel-rect, w, h, center, top, zero-edge).x, 4.0)
#assert.eq(_inside-anchor(panel-rect, w, h, left, top, zero-edge).x, 1.0)
#assert.eq(_inside-anchor(panel-rect, w, h, left, bottom, zero-edge).top, 3.0)
#assert.eq(_inside-anchor(panel-rect, w, h, left, horizon, zero-edge).top, 5.0)
#assert.eq(_inside-anchor(panel-rect, w, h, left, top, zero-edge).top, 7.0)

// A symmetric edge leaves the centred branches put: the left/right (resp.
// top/bottom) terms cancel out of the average.
#let sym-edge = (top: 0.2, right: 0.2, bottom: 0.2, left: 0.2)
#assert.eq(_inside-anchor(panel-rect, w, h, center, top, sym-edge).x, 4.0)
#assert.eq(_inside-anchor(panel-rect, w, h, left, horizon, sym-edge).top, 5.0)
#assert.eq(_inside-anchor(panel-rect, w, h, right, top, sym-edge).x, 6.8)
#assert.eq(_inside-anchor(panel-rect, w, h, left, top, sym-edge).x, 1.2)
#assert.eq(_inside-anchor(panel-rect, w, h, left, top, sym-edge).top, 6.8)
#assert.eq(_inside-anchor(panel-rect, w, h, left, bottom, sym-edge).top, 3.2)

// An asymmetric edge shifts the centred branches by half the side
// difference.
#let asym-edge = (top: 0.2, right: 0.3, bottom: 0.05, left: 0.1)
#approx-eq(_inside-anchor(panel-rect, w, h, center, top, asym-edge).x, 3.9)
#approx-eq(
  _inside-anchor(panel-rect, w, h, left, horizon, asym-edge).top,
  4.925,
)

// Containment invariant: for every alignment combination, the painted rect
// (bbox grown by `edge` on each side) stays inside `panel-rect`. This is the
// property the reported bug violated.
#for h-align in (left, center, right) {
  for v-align in (top, horizon, bottom) {
    let anchor = _inside-anchor(panel-rect, w, h, h-align, v-align, asym-edge)
    assert(
      anchor.x - asym-edge.left >= panel-rect.x - 1e-9,
      message: "left overflow at " + repr((h-align, v-align)),
    )
    assert(
      anchor.x + w + asym-edge.right <= panel-rect.x + panel-rect.w + 1e-9,
      message: "right overflow at " + repr((h-align, v-align)),
    )
    assert(
      anchor.top + asym-edge.top <= panel-rect.y + panel-rect.h + 1e-9,
      message: "top overflow at " + repr((h-align, v-align)),
    )
    assert(
      anchor.top - h - asym-edge.bottom >= panel-rect.y - 1e-9,
      message: "bottom overflow at " + repr((h-align, v-align)),
    )
  }
}

// `_bg-metrics`: `pad` is gated on the rect actually painting; `gap` is not.
//
// No fill or stroke -> nothing painted, `pad` and `gap` both zero, so no
// existing (unthemed) plot moves.
#let ctx = (canvas-w: 10.0, canvas-h: 6.0)
#let plain = _bg-metrics(merge-theme(none), ctx, w, h)
#assert.eq(plain.painted, false)
#assert.eq(plain.pad, zero-edge)
#assert.eq(plain.gap, zero-edge)
#assert.eq(_bg-edge-cm(plain), zero-edge)

// A fill without an explicit inset paints, and `pad` picks up the
// `element-rect` default of 5pt on every side.
#let pt-cm = 2.54 / 72
#let filled = _bg-metrics(
  merge-theme(theme(legend-background: element-rect(fill: rgb("#eeeeee")))),
  ctx,
  w,
  h,
)
#assert.eq(filled.painted, true)
#approx-eq(filled.pad.left, 5 * pt-cm)
#approx-eq(_bg-edge-cm(filled).left, 5 * pt-cm)

// An outset with no fill or stroke stays unpainted -- `pad` is zero -- but
// `gap` still resolves, matching `_rect-outset-cm`'s unconditional read used
// by chrome layout reservation and the side-legend gap.
#let outset-only = _bg-metrics(
  merge-theme(theme(
    legend-background: element-rect(outset: margin(right: 0.6cm)),
  )),
  ctx,
  w,
  h,
)
#assert.eq(outset-only.painted, false)
#assert.eq(outset-only.pad, zero-edge)
#assert.eq(outset-only.gap.right, 0.6)
#assert.eq(_bg-edge-cm(outset-only).right, 0.6)

Legend inside-anchor tests passed.
