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
// The second block pins the same flank under a themed `legend-text` angle. The
// draw turns the label, so the reservation reads the turned box.
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
  _max-break-label-box, _title-box, guides-for,
)
#import "../../src/guide/gizmo/bar.typ": bar-lead
#import "../../src/guide/gctx.typ": gctx
#import "../../src/theme/defaults.typ": merge-theme
#import "../../lib.typ": element-text, theme

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
  let label-w = _max-break-label-box(bar, breaks, _legend-text-style(th)).width
  // The one formula the draw places a label with, rather than a copy of it.
  // What this catches is the reservation ceasing to read it, as it did when a
  // rounded constant stood here. A change inside `bar-lead` moves the draw and
  // this test together, which is the point: the two can no longer disagree,
  // and the goldens are what notice the move.
  let lead = bar-lead(gctx("right", "legend"))
  // Stated outright, so this file carries the geometry it claims to pin rather
  // than only the wiring: a tick of 0.1 cm and a gap of 0.08 cm after it.
  assert(
    calc.abs(lead - 0.18) < 1e-9,
    message: "the drawn lead is " + repr(lead) + ", not 0.18",
  )
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

// The same flank, under a themed turn.
//
// The draw applies the `legend-text` angle to the label, so the reservation has
// to read the turned box rather than the upright one. A 45 degree turn on a
// three-character label presents more width than the label has flat, which is
// width the flank never reserved.
#context {
  let th = merge-theme(theme(legend-text: element-text(angle: 45deg)))
  let guides = guides-for(_spec, _trained, theme: th)
  let bar = guides.at(0)
  assert.eq(bar.placement.direction, "vertical")

  let breaks = _colourbar-breaks(bar)
  let turned = _max-break-label-box(bar, breaks, _legend-text-style(th))
  // The upright measure to compare against comes from a surface that differs
  // in its angle alone. An `element-text` replaces the whole themed element,
  // so the default theme would also measure at another size, and the two boxes
  // would differ for a reason that is not the turn.
  let flat = _max-break-label-box(
    bar,
    breaks,
    _legend-text-style(merge-theme(theme(
      legend-text: element-text(angle: 0deg),
    ))),
  )
  // The precondition: the turn must move the box at all, or the assertion
  // below would hold just as well against the upright measure.
  assert(
    turned.width > flat.width,
    message: "a 45 degree turn left the label box at "
      + repr(turned.width)
      + ", which is not wider than the upright "
      + repr(flat.width),
  )

  let lead = bar-lead(gctx("right", "legend"))
  let expected = _COLOURBAR-V-W + lead + turned.width

  let title-w = _title-box(bar, _legend-title-style(th)).width
  assert(
    title-w < expected,
    message: "the fixture title is "
      + repr(title-w)
      + " wide, which is not narrower than the strip and its turned labels at "
      + repr(expected),
  )

  assert(
    calc.abs(bar.width - expected) < 1e-9,
    message: "a vertical colour bar with turned labels reserved "
      + repr(bar.width)
      + " for a strip of "
      + repr(_COLOURBAR-V-W)
      + ", a drawn lead of "
      + repr(lead)
      + ", and turned labels of "
      + repr(turned.width),
  )
}

Colour bar reserve tests passed.
