// Smoke render: one tick row and one spine drawn on each of the four sides,
// straight onto a bare cetz canvas with no plot around them.
//
// Read each panel for what the unit tests cannot assert: every tick points away
// from the rectangle rather than into it, the ticks sit on their breaks, and the
// spine runs the full edge. The bottom and top rows should mirror each other,
// as should the left and right columns.

#import "../../src/deps.typ": cetz
#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/guide/entry.typ": entries-manual, train-entries
#import "../../src/guide/primitive/line.typ": prim-line
#import "../../src/guide/primitive/ticks.typ": prim-ticks
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/theme/theme.typ": _line-stroke, _tick-length
#import "../../src/theme/defaults.typ": default-theme, resolve-colour

#set page(width: auto, height: auto, margin: 0.5cm)

#let th = default-theme
#let ink = resolve-colour(th, "ink")
#let len-of = surface => _tick-length(th, surface) / 1cm
#let stroke-of = surface => _line-stroke(th, surface, fallback-colour: ink)

// Five breaks across the span, so the ends and the middle are both visible.
#let rows = train-entries(entries-manual((0, 1, 2, 3, 4)), v => v / 4)

#let px = (1.0, 6.0)
#let py = (1.0, 4.0)

#cetz.canvas({
  import cetz.draw: rect

  // The panel the guides hang off, drawn faintly so the tick direction reads.
  rect((px.at(0), py.at(0)), (px.at(1), py.at(1)), stroke: 0.4pt + luma(70%))

  for (position, aesthetic) in (
    ("bottom", "x"),
    ("top", "x"),
    ("left", "y"),
    ("right", "y"),
  ) {
    let ctx = gctx(
      position,
      aesthetic,
      tick-length: len-of,
      surface-stroke: stroke-of,
      place: place-cartesian(position, px, py),
    )
    registry.draw(prim-line(), ctx)
    registry.draw(prim-ticks(), ctx, entries: rows)
  }
})
