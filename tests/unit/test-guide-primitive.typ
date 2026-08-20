// The first guide primitives: the spine, the tick rows, and the blank spacer.
// Measurement is asserted against the helpers the axis stage already uses, so
// the port is checked mechanically rather than by eye.

#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/guide/entry.typ": (
  entries-manual, entries-tiered, train-entries,
)
#import "../../src/guide/primitive/common.typ": PRIMITIVE, measured
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
#let legend = gctx(
  "right",
  "colour",
  tick-length: len-of,
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
#let line-b = registry.measure(prim-line(), bottom)
#assert.eq(line-b.across, 0.0)
#assert.eq(line-b.along, 1.0)

// A legend has no line surface, so the same spine measures nothing there. The
// asymmetry is a tested fact rather than a comment.
#assert.eq(registry.measure(prim-line(), legend), measured())

// Major ticks reserve the resolved `axis-ticks` length: 0.1cm by default.
#let ticks-b = registry.measure(prim-ticks(), bottom, entries: majors)
#assert.eq(ticks-b.across, 0.1)
#assert.eq(ticks-b.along, 1.0)
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

// Beside a legend the tick length comes from the two constants the colour bar
// has always drawn at, not from the theme.
#assert.eq(registry.measure(prim-ticks(), legend, entries: majors).across, 0.1)

Guide-primitive tests passed.
