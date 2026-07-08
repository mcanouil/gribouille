// Legend fit: `side-stacked-height` sums the rendered guide heights plus an
// inter-guide gap, the value the renderer compares against the available band
// to decide whether a side legend overruns the caption.
//
// The overrun panic itself (in `render-plot`) cannot be caught in a unit test;
// it is exercised manually via a short plot with a caption and a tall legend.

#import "../../src/render/legend.typ": side-stacked-height
#import "../../src/theme/grey.typ": theme-grey

#let th = theme-grey()
#let ctx = (canvas-w: 10.0, canvas-h: 8.0)

// Custom guides reserve `cm-height + 0.2` each (no title prefix here), so the
// arithmetic is independent of font measurement.
#let cg(h) = (kind: "custom", cm-height: h, title: none)

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
// trips the renderer's caption-overrun guard.
#assert.eq(
  side-stacked-height("left", (cg(1.0), cg(1.0), cg(1.0)), ctx, th, 0.5),
  1.2 * 3 + 0.5 * 2,
)

Legend fit tests passed.
