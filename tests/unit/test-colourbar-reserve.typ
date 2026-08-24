// A vertical colour bar reserves the flank it draws.
//
// The renderer places a break label at `tick length + tick gap` past the strip
// (`src/guide/gizmo/bar.typ`, `lead`), which is `0.1 + 0.08` in legend context.
// The reservation used to approximate that with a named `0.3`, so a vertical
// colour bar took 0.12 cm more width than it ever painted.
//
// This pins the reservation against the geometry the draw asks for, through the
// same `tick-metrics` call, so the two cannot drift apart again.
//
// Only the vertical flank is pinned. The horizontal band is one fixed number
// covering the same lead plus a row of text, and is deliberately left
// unpinned here until it is unpicked in turn.
//
// The guide width is the wider of its title and its strip, so the fixture maps
// a single-character column: a wide title would set the width instead, and the
// assertion below would blame the reservation for a title effect. The first
// assertion keeps that precondition honest.

#import "../../src/render/legend.typ": (
  _COLOURBAR-V-W, _colourbar-breaks, _legend-text-style, _legend-title-style,
  _max-break-label-width, _title-box, guides-for,
)
#import "../../src/guide/gizmo/bar.typ": bar-lead
#import "../../src/guide/gctx.typ": gctx
#import "../../src/theme/defaults.typ": merge-theme
#import "../../lib.typ": theme

#let _spec = (
  mapping: (colour: "v"),
  layers: ((name: "point", mapping: none, inherit-aes: true, params: (:)),),
  guides: (:),
)
#let _trained = (colour: (type: "continuous", domain: (0, 100)))

// `guides-for` measures its labels, so the call and the assertions that read it
// sit inside one `context` block.
#context {
  let th = merge-theme(theme())
  let guides = guides-for(_spec, _trained, theme: th)
  assert.eq(guides.len(), 1)
  let bar = guides.at(0)
  assert.eq(bar.kind, "colourbar")
  // The reservation below is the vertical one, so the fixture must resolve to
  // a vertical bar for the assertion to be about what it claims.
  assert.eq(bar.placement.direction, "vertical")

  let breaks = _colourbar-breaks(bar)
  let label-w = _max-break-label-width(bar, breaks, _legend-text-style(th))
  // The one formula the draw places a label with, rather than a copy of it.
  // What this catches is the reservation ceasing to read it, as it did when a
  // rounded constant stood here. A change inside `bar-lead` moves the draw and
  // this test together, which is the point: the two can no longer disagree,
  // and the goldens are what notice the move.
  let lead = bar-lead(gctx("right", "legend"))
  // Stated outright, so this file carries the geometry it claims to pin rather
  // than only the wiring: a tick of 0.1 cm and a gap of 0.08 cm after it.
  assert.eq(lead, 0.18)
  let expected = _COLOURBAR-V-W + lead + label-w

  // The precondition: the title must not be what sets the width.
  let title-w = _title-box(bar, _legend-title-style(th)).width
  assert(
    title-w < expected,
    message: "the fixture title is "
      + repr(title-w)
      + " wide, which is not narrower than the strip and its labels at "
      + repr(expected),
  )

  assert(
    calc.abs(bar.width - expected) < 1e-9,
    message: "vertical colour bar reserved "
      + repr(bar.width)
      + " for a strip of "
      + repr(_COLOURBAR-V-W)
      + ", a drawn lead of "
      + repr(lead)
      + ", and labels of "
      + repr(label-w),
  )
}

Colour bar reserve tests passed.
