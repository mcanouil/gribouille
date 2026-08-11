// Standalone legend canvas sizing: `standalone-size` measures the hoisted
// `compose()` legend with `_draw-side`'s own arithmetic (guide render heights
// stacked by `_side-stack-gap`) and then grows the canvas by the
// `legend-background` edge -- painted `inset` plus reserved `outset` -- so the
// themed backdrop is not cut off by `standalone`'s `clip: true`.

#import "../../src/render/legend.typ": side-stacked-height, standalone-size
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

// Custom guides reserve `cm-height + 0.2` each (no title prefix here) and carry
// their width verbatim, so the arithmetic is independent of font measurement.
#let cg(w, h) = (
  kind: "custom",
  cm-width: w,
  cm-height: h,
  width: w,
  title: none,
)

#let grey = theme-grey()
#let one = (cg(2.0, 1.0),)
#let two = (cg(2.0, 1.0), cg(3.0, 2.0))

// theme-grey paints no legend background and sets no outset, so the canvas is
// the bare content box on every side.
#for side in ("right", "left", "top", "bottom") {
  let s = standalone-size(two, side, grey, canvas-w, canvas-h)
  assert.eq(s.edge, zero-edge, message: "edge on " + side)
  assert.eq(s.pad, zero-edge, message: "pad on " + side)
  assert.eq(s.width, s.content-w, message: "width on " + side)
  assert.eq(s.height, s.content-h, message: "height on " + side)
}

// Vertical sides: width is the widest guide, height is the stacked height the
// draw pass walks, so canvas and cursor never disagree.
#let vertical = standalone-size(two, "right", grey, canvas-w, canvas-h)
#assert.eq(vertical.content-w, 3.0)
#assert.eq(
  vertical.content-h,
  side-stacked-height(
    "right",
    two,
    (canvas-w: canvas-w, canvas-h: canvas-h),
    grey,
    0.0,
  ),
)
#assert.eq(vertical.content-h, 1.2 + 2.2)

// Horizontal sides: width is the row of guides plus one inter-guide gap per
// join (zero here), height is the tallest rendered guide.
#let horizontal = standalone-size(two, "top", grey, canvas-w, canvas-h)
#assert.eq(horizontal.content-w, 5.0)
#assert.eq(horizontal.content-h, 2.2)

// A single guide takes no inter-guide gap on either axis.
#assert.eq(standalone-size(one, "top", grey, canvas-w, canvas-h).content-w, 2.0)
#assert.eq(
  standalone-size(one, "right", grey, canvas-w, canvas-h).content-h,
  1.2,
)

// A painted background grows the canvas by exactly the per-side edge: the
// `inset` the rect paints outward plus the `outset` reserved around it.
#let themed = merge-theme(theme(legend-background: element-rect(
  fill: rgb("#e6f4ea"),
  colour: rgb("#2e7d4a"),
  stroke: 0.4pt,
  inset: margin(top: 0.1cm, right: 0.2cm, bottom: 0.3cm, left: 0.4cm),
  outset: margin(top: 0.05cm, right: 0.15cm, bottom: 0.25cm, left: 0.35cm),
)))
#let boxed = standalone-size(two, "right", themed, canvas-w, canvas-h)
#approx-eq(boxed.edge.left, 0.4 + 0.35)
#approx-eq(boxed.edge.right, 0.2 + 0.15)
#approx-eq(boxed.edge.top, 0.1 + 0.05)
#approx-eq(boxed.edge.bottom, 0.3 + 0.25)
#approx-eq(boxed.width, boxed.content-w + boxed.edge.left + boxed.edge.right)
#approx-eq(boxed.height, boxed.content-h + boxed.edge.top + boxed.edge.bottom)
#approx-eq(boxed.pad.left, 0.4)
#approx-eq(boxed.pad.bottom, 0.3)

// The panel-facing outset also separates stacked guides, so a themed outset
// grows the content box itself, not just the surrounding edge.
#approx-eq(boxed.content-h, 1.2 + 2.2 + 0.35)
#approx-eq(
  standalone-size(two, "top", themed, canvas-w, canvas-h).content-w,
  5.0 + 0.25,
)

// An `inset` on a rect that paints nothing gives no padding -- `_bg-metrics`
// gates `pad` on `painted` -- but the `outset` still reserves its space.
#let unpainted = merge-theme(theme(legend-background: element-rect(
  inset: margin(top: 0.4cm, right: 0.4cm, bottom: 0.4cm, left: 0.4cm),
  outset: margin(right: 0.6cm),
)))
#let bare = standalone-size(one, "right", unpainted, canvas-w, canvas-h)
#assert.eq(bare.pad, zero-edge)
#approx-eq(bare.edge.right, 0.6)
#approx-eq(bare.width, bare.content-w + 0.6)

// Containment invariant: the painted rect, placed at the origin `standalone`
// hands `_draw-side`, stays inside the canvas on every side. This is the
// property the reported bug violated.
#for side in ("right", "left", "top", "bottom") {
  let s = standalone-size(two, side, themed, canvas-w, canvas-h)
  let ox = if side == "right" { s.pad.left } else { s.edge.left }
  let oy = if side == "top" { s.pad.bottom } else { s.edge.bottom }
  // `_draw-side` adds the panel-facing outset back on the right/top branches,
  // so both origins land on the full `edge` once its cursor math has run.
  let x0 = ox + (if side == "right" { s.edge.left - s.pad.left } else { 0.0 })
  let y0 = oy + (if side == "top" { s.edge.bottom - s.pad.bottom } else { 0.0 })
  let x1 = x0 + s.content-w
  let y1 = y0 + s.content-h
  assert(x0 - s.pad.left >= -1e-9, message: "left overflow on " + side)
  assert(y0 - s.pad.bottom >= -1e-9, message: "bottom overflow on " + side)
  assert(
    x1 + s.pad.right <= s.width + 1e-9,
    message: "right overflow on " + side,
  )
  assert(
    y1 + s.pad.top <= s.height + 1e-9,
    message: "top overflow on " + side,
  )
}

Legend standalone-size tests passed.
