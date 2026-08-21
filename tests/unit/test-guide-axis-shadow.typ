// The axis as a stack of primitives, measured against the band the chrome
// stage reserves today. Nothing draws from this yet: the assertions below are
// the proof that it can, because every case answers the incumbent number.
//
// Reference values come from the chrome helpers themselves rather than from
// hand-typed constants, so a change to either side has to move both.

#import "../../src/guide/axis-build.typ": axis-node, axis-row
#import "../../src/guide/compose.typ": layout-of
#import "../../src/guide/entry.typ": (
  entries-manual, entries-tiered, train-entries,
)
#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/render/extents.typ": (
  _AX-TITLE-LABEL-GAP, _TICK-LABEL-GAP, _TITLE-EDGE-PAD, _X-LABEL-ROW-GAP,
  _Y-LABEL-COL-GAP, _band-gap-cm, _title-pad-cm, _x-label-depth, _y-label-width,
)
#import "../../src/theme/theme.typ": _line-stroke, _tick-length, tick-reach
#import "../../src/theme/defaults.typ": default-theme, resolve-colour

#import "../../src/utils/errors.typ": type-text

#let th = default-theme
#let ink = resolve-colour(th, "ink")

// The label geometry the render stage stamps on every entry. The widest is
// 1.2cm by 0.4cm, which is what both sides size their band from.
#let LABEL-W = 1.2
#let LABEL-H = 0.4
#let rows = train-entries(
  entries-manual((0, 5, 10), labels: v => str(v)),
  v => v / 10,
).map(e => (
  ..e,
  width: if e.value == 5 { LABEL-W } else { 0.8 },
  height: LABEL-H,
))

#let styles = _ => (render: label => [#label], align: left)

// A context that resolves a tick length of `tick` centimetres, so a case can
// ask for an axis with ticks and one without through the same builder.
#let ctx-for(position, axis, tick) = gctx(
  position,
  axis,
  tick-length: _ => tick,
  surface-stroke: _ => _line-stroke(
    th,
    "axis-line-x-bottom",
    fallback-colour: ink,
  ),
  text-style: styles,
  place: place-cartesian(position, (2.0, 7.0), (1.0, 5.0)),
)

// The band a side reserves today: the ticks, the labels, and the gap that holds
// them off the panel edge, which is owed whenever either of them reserves.
#let band-of(tick, depth) = tick + depth + _band-gap-cm(tick + depth)

#let depth-x(angle: 0, n-dodge: 1) = _x-label-depth(
  angle,
  n-dodge,
  LABEL-W,
  LABEL-H,
)
#let depth-y(angle: 0, n-dodge: 1) = _y-label-width(
  angle,
  n-dodge,
  LABEL-W,
  LABEL-H,
)

#let across-of(node, ctx) = calc.round(layout-of(node, ctx).across, digits: 9)
#let expect(value) = calc.round(value, digits: 9)

// A plain bottom axis: one tick row, one label row, and the gap between them.
#let TICK = _tick-length(th, "axis-ticks-x-bottom") / 1cm
#let bottom = ctx-for("bottom", "x", TICK)
#let plain-x = axis-node(
  entries: rows,
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(across-of(plain-x, bottom), expect(band-of(TICK, depth-x())))

// The same axis on the left, where the band is the label width rather than its
// height, and the tick length is the one that side resolves.
#let TICK-Y = _tick-length(th, "axis-ticks-y-left") / 1cm
#let left = ctx-for("left", "y", TICK-Y)
#let plain-y = axis-node(
  entries: rows,
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(across-of(plain-y, left), expect(band-of(TICK-Y, depth-y())))

// A turned label deepens the band by its rotated extent, on both sides.
#let turned-x = axis-node(
  entries: rows,
  rows: (axis-row(angle: 45),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(
  across-of(turned-x, bottom),
  expect(band-of(TICK, depth-x(angle: 45))),
)

// Dodged rows add one gap per extra row, which is the same figure the depth
// helper adds.
#let dodged = axis-node(
  entries: rows,
  rows: (axis-row(n-dodge: 3),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(
  across-of(dodged, bottom),
  expect(band-of(TICK, depth-x(n-dodge: 3))),
)
// The extra rows are the row gap the axis draw dodges by, not a number of this
// module's own.
#assert.eq(
  expect(across-of(dodged, bottom) - across-of(plain-x, bottom)),
  expect(2 * _X-LABEL-ROW-GAP),
)

// A stacked axis reserves each sub-guide's rows plus the spacing between them,
// which is what `_stacked-extent` sums today.
#let STACK-GAP = 0.2
#let stacked = axis-node(
  entries: rows,
  rows: (axis-row(), axis-row(angle: 45)),
  stack-gap: STACK-GAP,
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(
  across-of(stacked, bottom),
  expect(band-of(TICK, depth-x() + depth-x(angle: 45) + STACK-GAP)),
)

// An axis with no tick length still holds its labels off the edge, because the
// gap is owed by the band rather than by the tick.
#let no-ticks = ctx-for("bottom", "x", 0.0)
#let unticked = axis-node(
  entries: rows,
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(across-of(unticked, no-ticks), expect(band-of(0.0, depth-x())))

// An axis with ticks and no labels reserves the gap all the same, which is what
// the chrome stage has always kept past the tick row.
#let ticks-only = axis-node(
  entries: rows.map(e => (..e, width: 0.0, height: 0.0)),
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(across-of(ticks-only, bottom), expect(band-of(TICK, 0.0)))

// A stripped axis reserves nothing at all: no ticks, no labels, no gap. This is
// what `theme-void` and `guides(x: none)` leave the panel.
#let stripped = axis-node(
  entries: rows.map(e => (..e, width: 0.0, height: 0.0)),
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(across-of(stripped, no-ticks), 0.0)

// A title adds the gap its surface asks for, its own box, and the pad past it,
// which is the bottom-side total the chrome stage reserves.
#let TITLE-H = 0.35
#let TITLE-GAP = _AX-TITLE-LABEL-GAP / 1cm
#let titled = axis-node(
  entries: rows,
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
  title: [Weight],
  title-extent: (3.0, TITLE-H),
  title-gap: TITLE-GAP,
  title-pad: _TITLE-EDGE-PAD,
)
#assert.eq(
  across-of(titled, bottom),
  expect(
    band-of(TICK, depth-x()) + TITLE-GAP + TITLE-H + _title-pad-cm(TITLE-H),
  ),
)

// A titleless axis reserves neither the gap nor the pad, even when both are
// offered, so the panel keeps the room. That gate is the reason both are
// spacers rather than constants.
#let untitled = axis-node(
  entries: rows,
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
  title: none,
  title-gap: TITLE-GAP,
  title-pad: _TITLE-EDGE-PAD,
)
#assert.eq(across-of(untitled, bottom), expect(band-of(TICK, depth-x())))

// A title the theme blanked measures nothing, so it takes neither gap either.
// Reserving them would push the panel in around ink that never draws, which is
// the failure the chrome stage guards with the same gate.
#let blanked = axis-node(
  entries: rows,
  rows: (axis-row(),),
  band-gap: _TICK-LABEL-GAP,
  title: [Weight],
  title-extent: (0.0, 0.0),
  title-gap: TITLE-GAP,
  title-pad: _TITLE-EDGE-PAD,
)
#assert.eq(across-of(blanked, bottom), expect(band-of(TICK, depth-x())))

// The y label column gap is the one the vertical dodge uses, so a dodged left
// axis grows by it rather than by the x figure.
#let dodged-y = axis-node(
  entries: rows,
  rows: (axis-row(n-dodge: 2),),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(
  expect(across-of(dodged-y, left) - across-of(plain-y, left)),
  expect(_Y-LABEL-COL-GAP),
)

// A log axis draws three tick weights, and its band takes the longest of them,
// which is what `tick-reach` answers for the chrome stage.
#let log-rows = train-entries(
  entries-tiered((1, 10, 100), mid: (5, 50), minor: (2, 20)),
  v => calc.log(v, base: 10) / 2,
).map(e => (..e, width: 0.0, height: 0.0))
#let themed = gctx(
  "bottom",
  "x",
  tick-length: surface => _tick-length(th, surface) / 1cm,
  surface-stroke: _ => _line-stroke(
    th,
    "axis-line-x-bottom",
    fallback-colour: ink,
  ),
  text-style: styles,
  place: place-cartesian("bottom", (2.0, 7.0), (1.0, 5.0)),
)
#let log-axis = axis-node(
  entries: log-rows,
  rows: (axis-row(),),
  tiers: ("major", "mid", "minor"),
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(
  across-of(log-axis, themed),
  expect(band-of(tick-reach(th, "x-bottom", "x") / 1cm, 0.0)),
)

// The top and the right reserve the same band as the sides opposite them. Only
// the direction the parts grow in changes, and that belongs to `place`.
#let top = ctx-for("top", "x", TICK)
#let right = ctx-for("right", "y", TICK-Y)
#assert.eq(across-of(plain-x, top), expect(band-of(TICK, depth-x())))
#assert.eq(across-of(plain-y, right), expect(band-of(TICK-Y, depth-y())))

// A stated dodge gap overrides the one the side would pick, so an axis can
// dodge at a spacing of its own.
#let wide-dodge = axis-node(
  entries: rows,
  rows: (axis-row(n-dodge: 2),),
  dodge-gap: 1.0,
  band-gap: _TICK-LABEL-GAP,
)
#assert.eq(
  expect(across-of(wide-dodge, bottom) - across-of(plain-x, bottom)),
  1.0,
)

// An axis with no label rows at all is legal: a secondary edge draws its ticks
// and leaves the labels to the edge opposite.
#let rowless = axis-node(entries: rows, rows: (), band-gap: _TICK-LABEL-GAP)
#assert.eq(across-of(rowless, bottom), expect(band-of(TICK, 0.0)))

// A row that is not a row fails by the name of the builder that makes one.
#assert.eq(
  type-text(
    "guide-axis",
    "row 0",
    45,
    "a row carrying `angle` and `n-dodge`",
    hint: "Build each with `axis-row`.",
  ),
  "guide-axis: row 0 must be a row carrying `angle` and `n-dodge`; got 45. Build each with `axis-row`.",
)

Guide-axis-shadow tests passed.\n