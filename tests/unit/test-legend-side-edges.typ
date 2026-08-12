// Side-placed legend background: `side-bg-edges` measures, per plot side, the
// cm the `legend-background` claims outside the guide-stack bbox -- the painted
// `inset` plus the reserved `outset` -- so `_chrome-margins` reserves the whole
// painted rect rather than only its outset. `_side-origin-shift` is the matching
// offset `_draw-side` applies to its cursor, so the reserved slot and the drawn
// rect cannot disagree.

#import "../../src/render/legend.typ": (
  _bg-metrics, _side-origin-shift, side-bg-edges, side-stacked-height,
)
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/grey.typ": theme-grey
#import "../../lib.typ": element-rect, margin, theme

#let approx-eq(a, b, tol: 1e-9) = {
  let diff = a - b
  if diff < 0 { diff = -diff }
  assert(diff < tol, message: "expected " + repr(a) + " ~= " + repr(b))
}

#let zero-edge = (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0)
#let canvas-w = 12.0
#let canvas-h = 8.0
#let ctx = (canvas-w: canvas-w, canvas-h: canvas-h)
#let legend-gap = 0.3

// Custom guides reserve `cm-height + 0.2` each (no title prefix here) and carry
// their width verbatim, so the arithmetic is independent of font measurement.
#let cg(w, h, side) = (
  kind: "custom",
  cm-width: w,
  cm-height: h,
  width: w,
  title: none,
  placement: (side: side),
)

#let grey = theme-grey()

// theme-grey paints no legend background and sets no outset: every side keeps
// today's reservation and every draw origin stays put.
#let bare = side-bg-edges(
  ("top", "right", "bottom", "left").map(s => cg(2.0, 1.0, s)),
  ctx,
  grey,
  legend-gap,
)
#for side in ("top", "right", "bottom", "left") {
  assert.eq(bare.at(side), zero-edge, message: "edge on " + side)
  let shift = _side-origin-shift(side, _bg-metrics(grey, ctx, 2.0, 1.0))
  assert.eq(shift.dx, 0.0, message: "dx on " + side)
  assert.eq(shift.dy, 0.0, message: "dy on " + side)
}

// A side with no guides claims nothing, so an empty side never inflates the
// margin of the side opposite it.
#let one-side = side-bg-edges((cg(2.0, 1.0, "right"),), ctx, grey, legend-gap)
#for side in ("top", "bottom", "left") {
  assert.eq(one-side.at(side), zero-edge, message: "empty edge on " + side)
}

#let themed = merge-theme(theme(legend-background: element-rect(
  fill: rgb("#e6f4ea"),
  colour: rgb("#2e7d4a"),
  stroke: 0.4pt,
  inset: margin(top: 0.1cm, right: 0.2cm, bottom: 0.3cm, left: 0.4cm),
  outset: margin(top: 0.05cm, right: 0.15cm, bottom: 0.25cm, left: 0.35cm),
)))

// The edge is the painted inset plus the reserved outset, per side, on every
// side that carries guides.
#let boxed = side-bg-edges(
  ("top", "right", "bottom", "left").map(s => cg(2.0, 1.0, s)),
  ctx,
  themed,
  legend-gap,
)
#for side in ("top", "right", "bottom", "left") {
  let e = boxed.at(side)
  approx-eq(e.left, 0.4 + 0.35)
  approx-eq(e.right, 0.2 + 0.15)
  approx-eq(e.top, 0.1 + 0.05)
  approx-eq(e.bottom, 0.3 + 0.25)
}

// `_draw-side` already adds the panel-facing outset to its cursor on `right`
// and `top`, so those two shift by the inset alone; `left` and `bottom` anchor
// off the canvas edge and owe the full edge.
#let bg = _bg-metrics(themed, ctx, 2.0, 1.0)
#approx-eq(_side-origin-shift("right", bg).dx, 0.4)
#approx-eq(_side-origin-shift("left", bg).dx, 0.4 + 0.35)
#approx-eq(_side-origin-shift("top", bg).dy, 0.3)
#approx-eq(_side-origin-shift("bottom", bg).dy, 0.3 + 0.25)
#assert.eq(_side-origin-shift("right", bg).dy, 0.0)
#assert.eq(_side-origin-shift("top", bg).dx, 0.0)

// A `%` inset resolves against that side's own content box, which differs
// between a vertical stack and a horizontal row, so each side is measured
// against the bbox `_draw-side` actually walks.
#let pct = merge-theme(theme(legend-background: element-rect(
  fill: rgb("#e6f4ea"),
  inset: margin(top: 10%, right: 10%, bottom: 10%, left: 10%),
)))
#let two-v = (cg(2.0, 1.0, "right"), cg(3.0, 2.0, "right"))
#let two-h = (cg(2.0, 1.0, "top"), cg(3.0, 2.0, "top"))
#let pct-edges = side-bg-edges(two-v + two-h, ctx, pct, legend-gap)
// Vertical: content is the widest guide by the stacked height.
#let stacked = side-stacked-height("right", two-v, ctx, pct, legend-gap)
#approx-eq(pct-edges.right.left, 0.1 * 3.0)
#approx-eq(pct-edges.right.top, 0.1 * stacked)
// Horizontal: content is the row width by the tallest guide.
#approx-eq(pct-edges.top.left, 0.1 * (2.0 + 3.0 + legend-gap))
#approx-eq(pct-edges.top.top, 0.1 * 2.2)

// An `inset` on a rect that paints nothing claims no space -- `_bg-metrics`
// gates `pad` on `painted` -- but the `outset` still reserves its own.
#let unpainted = merge-theme(theme(legend-background: element-rect(
  inset: margin(top: 0.4cm, right: 0.4cm, bottom: 0.4cm, left: 0.4cm),
  outset: margin(right: 0.6cm),
)))
#let plain = side-bg-edges((cg(2.0, 1.0, "right"),), ctx, unpainted, legend-gap)
#approx-eq(plain.right.right, 0.6)
#approx-eq(plain.right.left, 0.0)
#approx-eq(
  _side-origin-shift("right", _bg-metrics(unpainted, ctx, 2.0, 1.0)).dx,
  0.0,
)

// Containment invariant, walked along the slot axis of each side. This is the
// property the reported bug violated: the painted rect grew past the reserved
// slot, and the canvas bounds, being the union of the drawn elements, grew with
// it.
#let opposite = (top: "bottom", right: "left", bottom: "top", left: "right")
#for side in ("top", "right", "bottom", "left") {
  let vertical = side == "right" or side == "left"
  let side-guides = (if vertical { two-v } else { two-h }).map(g => (
    g
      + (
        placement: (side: side),
      )
  ))
  let edge = side-bg-edges(side-guides, ctx, themed, legend-gap).at(side)
  let stacked = side-stacked-height(side, two-v, ctx, themed, legend-gap)
  let bg = _bg-metrics(
    themed,
    ctx,
    if vertical { 3.0 } else { 2.0 + 3.0 + legend-gap },
    if vertical { stacked } else { 2.2 },
  )
  // How deep the guide stack sits across the slot, and how deep a band
  // `_chrome-margins` reserves for it.
  let depth = if vertical { 3.0 } else { 2.2 }
  let near = opposite.at(side)
  let band = depth + legend-gap + edge.at(side) + edge.at(near)
  // One of the two components is zero: the shift runs along the slot axis.
  let shift = _side-origin-shift(side, bg)
  let offset = shift.dx + shift.dy

  if side == "right" or side == "top" {
    // Measured from the panel edge outward. `_side-stack-gap` contributes
    // `legend-gap + outset`, the shift the remaining `inset`.
    let content-near = legend-gap + edge.at(near) - bg.pad.at(near) + offset
    // The painted rect clears the panel by the full `legend-gap` ...
    assert(
      content-near - bg.pad.at(near) >= legend-gap - 1e-9,
      message: "painted rect eats the panel gap on " + side,
    )
    // ... and still ends within the band chrome reserved for it.
    assert(
      content-near + depth + bg.pad.at(side) <= band + 1e-9,
      message: "painted rect overruns the reserved band on " + side,
    )
  } else {
    // Measured from the canvas edge inward, past the fixed nudge `_draw-side`
    // anchors these two sides with. The painted rect must not cross it.
    let nudge = if side == "left" { 0.05 } else { 0.4 }
    assert(
      nudge + offset - bg.pad.at(side) >= -1e-9,
      message: "painted rect overruns the canvas edge on " + side,
    )
  }
}

Legend side-edge tests passed.
