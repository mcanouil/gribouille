// The first guide primitives: the spine, the tick rows, and the blank spacer.
// Measurement is asserted against the helpers the axis stage already uses, so
// the port is checked mechanically rather than by eye.

#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/guide/entry.typ": (
  TIERS, entries-manual, entries-tiered, train-entries,
)
#import "../../src/utils/errors.typ": enum-text, error-text
#import "../../src/guide/primitive/common.typ": PRIMITIVE, measured
#import "../../src/guide/primitive/content.typ": prim-content
#import "../../src/guide/primitive/line.typ": prim-line
#import "../../src/guide/primitive/spacer.typ": prim-spacer
#import "../../src/guide/primitive/ticks.typ": prim-ticks
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/theme/theme.typ": _line-stroke, _tick-length, tick-reach
#import "../../src/theme/defaults.typ": default-theme, resolve-colour

#let th = default-theme
#let ink = resolve-colour(th, "ink")
#let len-of = surface => _tick-length(th, surface) / 1cm
#let stroke-of = surface => _line-stroke(th, surface, fallback-colour: ink)

#let ctx-for(position, aesthetic, ..rest) = gctx(
  position,
  aesthetic,
  tick-length: len-of,
  surface-stroke: stroke-of,
  place: place-cartesian(
    if position == "theta" or position == "r" or position == "inside" {
      "bottom"
    } else { position },
    (2.0, 7.0),
    (1.0, 5.0),
  ),
  ..rest,
)

#let bottom = ctx-for("bottom", "x")
#let left = ctx-for("left", "y")
// The legend tick length must come from `LEGEND-TICK-LEN`, never from the
// theme, so this context resolves a length nothing else uses. An assertion of
// 0.1 would otherwise pass on either path.
#let legend = gctx(
  "right",
  "colour",
  tick-length: _ => 0.5,
  surface-stroke: stroke-of,
  place: place-cartesian("right", (2.0, 7.0), (1.0, 5.0)),
)

#let majors = train-entries(entries-manual((0, 5, 10)), v => v / 10)

// Every primitive is tagged the same way, so a composition can tell one from a
// nested composition without knowing the names.
#assert.eq(prim-line().kind, PRIMITIVE)
#assert.eq(prim-ticks().kind, PRIMITIVE)
#assert.eq(prim-spacer(0.4).kind, PRIMITIVE)
#assert.eq(prim-ticks().tiers, ("major",))

// A spacer reserves exactly what it was given, on every side.
#assert.eq(registry.measure(prim-spacer(0.4), bottom).across, 0.4)
#assert.eq(registry.measure(prim-spacer(0.4), left).across, 0.4)
#assert.eq(registry.measure(prim-spacer(0.4), legend).across, 0.4)

// The spine runs the length of the guide and adds no depth to the band.
// It reports no length of its own: it spans whatever the composition gives it,
// which is what `fills` says and what keeps `along` in centimetres throughout.
#let line-b = registry.measure(prim-line(), bottom)
#assert.eq(line-b.across, 0.0)
#assert.eq(line-b.along, 0.0)
#assert.eq(line-b.fills, true)

// A legend has no line surface, so the same spine measures nothing there. The
// asymmetry is a tested fact rather than a comment.
#assert.eq(registry.measure(prim-line(), legend), measured())

// Major ticks reserve the resolved `axis-ticks` length: 0.1cm by default.
#let ticks-b = registry.measure(prim-ticks(), bottom, entries: majors)
#assert.eq(ticks-b.across, 0.1)
#assert.eq(ticks-b.along, 0.0)
#assert.eq(ticks-b.fills, true)
#assert.eq(registry.measure(prim-ticks(), left, entries: majors).across, 0.1)

// With no entries there is nothing to tick, so nothing is reserved.
#assert.eq(registry.measure(prim-ticks(), bottom, entries: ()), measured())

// A log axis draws three weights. Depth is the longest tier that draws, which
// is what `tick-reach` answers for the axis stage, so the two agree.
#let log-rows = train-entries(
  entries-tiered((1, 10, 100), mid: (5, 50), minor: (2, 20)),
  v => calc.log(v, base: 10) / 2,
)
#let log-ticks = prim-ticks(tiers: ("major", "mid", "minor"))
#assert.eq(
  calc.round(
    registry.measure(log-ticks, bottom, entries: log-rows).across,
    digits: 6,
  ),
  calc.round(tick-reach(th, "x-bottom", "x") / 1cm, digits: 6),
)
#assert.eq(
  calc.round(
    registry.measure(log-ticks, left, entries: log-rows).across,
    digits: 6,
  ),
  calc.round(tick-reach(th, "y-left", "y") / 1cm, digits: 6),
)

// A tier with no entries of its own contributes no depth, so a plain axis that
// asks for the log tiers still reserves only the major length.
#assert.eq(
  registry.measure(log-ticks, bottom, entries: majors).across,
  0.1,
)

// A blanked tick surface draws nothing and reserves nothing, which is how
// `theme-void` and `guides(x: none)` keep the room.
#let blank-ctx = gctx(
  "bottom",
  "x",
  tick-length: _ => 0.0,
  surface-stroke: stroke-of,
  place: place-cartesian("bottom", (2.0, 7.0), (1.0, 5.0)),
)
#assert.eq(
  registry.measure(prim-ticks(), blank-ctx, entries: majors),
  measured(),
)

#let no-stroke = gctx(
  "bottom",
  "x",
  tick-length: len-of,
  surface-stroke: _ => none,
  place: place-cartesian("bottom", (2.0, 7.0), (1.0, 5.0)),
)
#assert.eq(
  registry.measure(prim-ticks(), no-stroke, entries: majors),
  measured(),
)

// Beside a legend the tick length comes from the constant the colour bar has
// always drawn at, not from the theme: this context's theme closure answers
// 0.5, so only the legend constant satisfies the assertion.
#assert.eq(registry.measure(prim-ticks(), legend, entries: majors).across, 0.1)

// A blanked spine measures nothing, because measure and draw gate on the same
// stroke. Without this, `theme-void` would reserve a line it never draws.
#assert.eq(registry.measure(prim-line(), no-stroke), measured())

// An opaque block takes exactly the room it was given, whichever side its
// legend box sits on, because a legend stacks its parts downward regardless.
#let block = prim-content([Note], width: 3.0, height: 2.0)
#assert.eq(registry.measure(block, legend).across, 2.0)
#assert.eq(registry.measure(block, legend).along, 3.0)
#assert.eq(registry.measure(block, bottom).across, 2.0)

// A zero dimension still reserves and still draws: Typst does not clip a box,
// so a block given no height kept showing its content before the guide layer
// and keeps showing it now.
#assert.eq(
  registry.measure(prim-content([Note], width: 3.0, height: 0.0), legend).along,
  3.0,
)

// Only a block with no body at all takes nothing.
#assert.eq(
  registry.measure(prim-content(none, width: 3.0, height: 2.0), legend),
  measured(),
)

// Rejection wording for the guards. An unknown tier fails where it is supplied
// rather than drawing an empty guide, and a negative spacer fails rather than
// eating a neighbour's room.
#assert.eq(
  enum-text("guide-ticks", "tier", "mnior", TIERS),
  "guide-ticks: tier must be one of \"major\", \"mid\", \"minor\"; got \"mnior\".",
)
#assert.eq(
  error-text(
    "guide-spacer",
    "space cannot be negative; got -0.4",
    hint: "Use a positive number of centimetres, or drop the spacer.",
  ),
  "guide-spacer: space cannot be negative; got -0.4. Use a positive number of centimetres, or drop the spacer.",
)
// Every registered primitive exposes the same pair, and an unregistered name is
// not silently drawable. Asserting the key set rather than a rendered message
// keeps this from rotting each time a primitive is added.
#assert(not registry.PRIMITIVES.keys().contains("wobble"))
#for (name, fns) in registry.PRIMITIVES {
  assert(
    type(fns.measure) == function and type(fns.draw) == function,
    message: name + " must expose measure and draw",
  )
}

// An untrained table is rejected at the boundary between the builder and the
// primitive, rather than panicking inside `place` on `none * float`.
#assert.eq(
  error-text(
    "guide-ticks",
    "entry 0 is untrained; its `frac` is `none`",
    hint: "Run the table through `train-entries` before drawing it.",
  ),
  "guide-ticks: entry 0 is untrained; its `frac` is `none`. Run the table through `train-entries` before drawing it.",
)

Guide-primitive tests passed.
