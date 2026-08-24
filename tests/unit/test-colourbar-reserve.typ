// A vertical colour bar reserves the flank it draws.
//
// The renderer places a break label at `tick length + tick gap` past the strip
// (`src/guide/gizmo/bar.typ`, `lead`), which is `0.1 + 0.08` in legend context.
// The reservation used to approximate that with a named `0.3`, so a vertical
// colour bar took 0.12 cm more width than it ever painted.
//
// This pins the reservation against the drawn geometry rather than against a
// number, so the two cannot drift apart again.

#import "../../src/render/legend.typ": (
  _COLOURBAR-V-W, _colourbar-breaks, _legend-text-style, _max-break-label-width,
  guides-for,
)
#import "../../src/guide/surface.typ": LEGEND-TICK-GAP, LEGEND-TICK-LEN
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

  let breaks = _colourbar-breaks(bar)
  let label-w = _max-break-label-width(bar, breaks, _legend-text-style(th))
  let lead = LEGEND-TICK-LEN + LEGEND-TICK-GAP
  let expected = _COLOURBAR-V-W + lead + label-w

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

colourbar reserve tests passed.
