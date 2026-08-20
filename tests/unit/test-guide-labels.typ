// The label and title primitives. Depth is asserted equal to the helpers the
// chrome stage reserves with today, on the same inputs, so the port is checked
// against the incumbent rather than by eye.

#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/guide/entry.typ": entries-manual, train-entries
#import "../../src/guide/primitive/common.typ": measured
#import "../../src/guide/primitive/labels.typ": (
  X-ROW-GAP, Y-COL-GAP, prim-labels,
)
#import "../../src/guide/primitive/title.typ": prim-title
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/render/extents.typ": _x-label-depth, _y-label-width
#import "../../src/utils/label-geometry.typ": _label-reach, _rotated-extent
#import "../../src/utils/errors.typ": error-text, range-text

// The gaps mirror the ones the chrome stage and the axis draw both apply.
#assert.eq(X-ROW-GAP, 0.35)
#assert.eq(Y-COL-GAP, 0.5)

#let styles = _ => (render: label => [#label], align: left)

#let ctx-for(position, aesthetic) = gctx(
  position,
  aesthetic,
  tick-length: _ => 0.1,
  surface-stroke: _ => 0.5pt + black,
  text-style: styles,
  place: place-cartesian(position, (2.0, 7.0), (1.0, 5.0)),
)

#let ctx-bottom = ctx-for("bottom", "x")
#let ctx-left = ctx-for("left", "y")

// A measured table: the render stage stamps each entry with its ink extents,
// as `_break-records` already does. The widest is 1.2cm by 0.4cm.
#let sized = train-entries(entries-manual((0, 5, 10)), v => v / 10).map(e => (
  ..e,
  width: if e.value == 5 { 1.2 } else { 0.8 },
  height: 0.4,
))

// An unturned row is as deep as the tallest label, on either side, which is
// what the depth helpers answer for one dodge row.
#assert.eq(
  registry.measure(prim-labels(), ctx-bottom, entries: sized).across,
  _x-label-depth(0, 1, 1.2, 0.4),
)
#assert.eq(
  registry.measure(prim-labels(), ctx-left, entries: sized).across,
  _y-label-width(0, 1, 1.2, 0.4),
)

// Turning the labels composes the two extents trigonometrically, and the flip
// picks the right one per side. Asserted against the incumbent at three angles.
#for a in (30, -45, 90) {
  assert.eq(
    calc.round(
      registry
        .measure(prim-labels(angle: a), ctx-bottom, entries: sized)
        .across,
      digits: 9,
    ),
    calc.round(_x-label-depth(a, 1, 1.2, 0.4), digits: 9),
  )
  assert.eq(
    calc.round(
      registry.measure(prim-labels(angle: a), ctx-left, entries: sized).across,
      digits: 9,
    ),
    calc.round(_y-label-width(a, 1, 1.2, 0.4), digits: 9),
  )
}

// Every extra dodge row adds one gap, and the gap differs per side.
#assert.eq(
  registry.measure(prim-labels(n-dodge: 3), ctx-bottom, entries: sized).across,
  _x-label-depth(0, 3, 1.2, 0.4),
)
#assert.eq(
  registry.measure(prim-labels(n-dodge: 3), ctx-left, entries: sized).across,
  _y-label-width(0, 3, 1.2, 0.4),
)

// Reach is reported apart from depth, because a turned corner-pinned label
// swings about its pin and overhangs the band's ends without deepening it.
#let turned = registry.measure(
  prim-labels(angle: 30),
  ctx-bottom,
  entries: sized,
)
#let spread = _label-reach(1.2, 0.4, 30, "north-east")
#assert.eq(turned.reach.near, spread.left)
#assert.eq(turned.reach.far, spread.right)

// An unturned x label is pinned at `north`, so it hangs below its break and
// spreads half its width each way.
#let flat = registry.measure(prim-labels(), ctx-bottom, entries: sized)
#assert.eq(calc.round(flat.reach.near, digits: 9), 0.6)
#assert.eq(calc.round(flat.reach.far, digits: 9), 0.6)

// Nothing to label, nothing reserved.
#assert.eq(registry.measure(prim-labels(), ctx-bottom, entries: ()), measured())

// Entries with no measured ink reserve nothing, so an axis whose labels were
// never measured cannot silently claim a band.
#let unsized = train-entries(entries-manual((0, 1)), v => v)
#assert.eq(
  registry.measure(prim-labels(), ctx-bottom, entries: unsized),
  measured(),
)

// A title is as deep as its turned box and as long as that box reads.
#let title = prim-title([Speed], extent: (2.0, 0.5))
#assert.eq(registry.measure(title, ctx-bottom).across, 0.5)
#assert.eq(registry.measure(title, ctx-bottom).along, 2.0)
// The same title on a vertical side transposes.
#assert.eq(registry.measure(title, ctx-left).across, 2.0)
#assert.eq(registry.measure(title, ctx-left).along, 0.5)

// Turned a quarter, the box swaps, matching `_rotated-extent`.
#let upright = prim-title([Speed], angle: 90, extent: (2.0, 0.5))
#assert.eq(
  calc.round(registry.measure(upright, ctx-left).across, digits: 9),
  calc.round(_rotated-extent(2.0, 0.5, 90).width, digits: 9),
)

// No body, or no measured ink, reserves nothing.
#assert.eq(registry.measure(prim-title(none), ctx-bottom), measured())
#assert.eq(registry.measure(prim-title([Speed]), ctx-bottom), measured())

// A span-filling primitive reports no length of its own; a title reports the
// length of its box. The two must never be summed, so they are distinguished
// by `fills` rather than by the units of `along`.
#assert.eq(
  registry.measure(prim-labels(), ctx-bottom, entries: sized).fills,
  true,
)
#assert.eq(
  registry.measure(prim-labels(), ctx-bottom, entries: sized).along,
  0.0,
)
#assert.eq(registry.measure(title, ctx-bottom).fills, false)

// Rejection wording for the guards. The bound is inclusive, since a quarter
// turn is accepted, so the message has to say so.
#assert.eq(
  range-text(
    "guide-labels",
    "angle",
    120,
    -90,
    90,
    lo-open: false,
    hi-open: false,
    hint: "A quarter turn either way is the limit; past it the labels read upside down.",
  ),
  "guide-labels: angle must be in [-90, 90]; got 120. A quarter turn either way is the limit; past it the labels read upside down.",
)
#assert.eq(
  error-text(
    "guide-labels",
    "n-dodge must be a whole number of at least 1; got 0",
    hint: "One row per dodge; use 1 for a single row.",
  ),
  "guide-labels: n-dodge must be a whole number of at least 1; got 0. One row per dodge; use 1 for a single row.",
)

Guide-labels tests passed.
