// Legend fit: `side-stacked-height` sums the rendered guide heights plus an
// inter-guide gap, and `side-block-cm` grows that stack by the background the
// theme paints and reserves around it. The second is the block the draw pass
// puts on the canvas, so it is what the chrome fit check measures against the
// requested `width`/`height`.
//
// The overrun panics themselves (in `_chrome-margins`) cannot be caught in a
// unit test; `tests/unit/test-legend-canvas-fit.typ` records their wording and
// the plots that raise them.

#import "../../src/render/legend.typ": side-block-cm, side-stacked-height
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/grey.typ": theme-grey
#import "../../lib.typ": element-rect, margin, theme

#let th = merge-theme(theme-grey())
#let ctx = (canvas-w: 10.0, canvas-h: 8.0)

// Custom guides reserve `cm-height + 0.2` each (no title prefix here), so the
// arithmetic is independent of font measurement.
#let cg(h) = (kind: "custom", cm-height: h, cm-width: 2.0, width: 2.0, title: none)

// No guides on the side -> zero height.
#assert.eq(side-stacked-height("right", (), ctx, th, 0.3), 0.0)

// A single guide reserves its own height with no inter-guide gap.
#assert.eq(side-stacked-height("right", (cg(1.0),), ctx, th, 0.3), 1.2)

// Two guides add both heights plus one gap (`legend-gap` here, theme-grey adds
// no legend-background outset).
#assert.eq(
  side-stacked-height("right", (cg(1.0), cg(2.0)), ctx, th, 0.3),
  1.2 + 2.2 + 0.3,
)

// More guides stack more gaps; height grows past any short plot, which is what
// trips the renderer's fit guard.
#assert.eq(
  side-stacked-height("left", (cg(1.0), cg(1.0), cg(1.0)), ctx, th, 0.5),
  1.2 * 3 + 0.5 * 2,
)

// Under a theme that paints no legend backdrop the block is the stack itself,
// on both axes, and the edge is zero all round.
#let plain = side-block-cm("right", (cg(1.0), cg(2.0)), ctx, th, 0.3)
#assert.eq(plain.content-h, 1.2 + 2.2 + 0.3)
#assert.eq(plain.height, plain.content-h)
#assert.eq(plain.width, plain.content-w)
#assert.eq(plain.edge, (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0))

// A themed backdrop claims its painted `inset` and its reserved `outset` on
// every side, and the block grows by both. The chrome slot has to hold that,
// not just the guide stack, or the figure outgrows the box it was given.
#let boxed = merge-theme(theme(legend-background: element-rect(
  fill: white,
  inset: margin(top: 0.25cm, right: 0.25cm, bottom: 0.25cm, left: 0.25cm),
  outset: margin(top: 0.1cm, right: 0.1cm, bottom: 0.1cm, left: 0.1cm),
)))
#let padded = side-block-cm("right", (cg(1.0), cg(2.0)), ctx, boxed, 0.3)
// The backdrop also spaces the stacked guides apart, by the outset on the edge
// each one faces, so the content box grows by that gap as well as by the edge.
#assert.eq(padded.content-h, plain.content-h + 0.1)
#assert.eq(padded.edge, (
  top: 0.35,
  right: 0.35,
  bottom: 0.35,
  left: 0.35,
))
#assert.eq(padded.height, padded.content-h + 0.7)
#assert.eq(padded.width, plain.content-w + 0.7)

// A horizontal side lays the guides out beside each other, so the same stack
// reads as width there rather than height.
#let along = side-block-cm("bottom", (cg(1.0), cg(2.0)), ctx, th, 0.3)
#assert.eq(along.content-w, 2.0 + 2.0 + 0.3)

Legend fit tests passed.
