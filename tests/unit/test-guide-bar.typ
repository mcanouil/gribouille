// The colour-bar gizmo: the box it reserves, on both directions, against the
// formulas the legend renderer sized a colour bar with before the port.

#import "../../src/guide/gctx.typ": gctx
#import "../../src/guide/gizmo/bar.typ": DIRECTIONS, prim-bar
#import "../../src/guide/primitive/common.typ": PRIMITIVE, measured
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/utils/errors.typ": enum-text, error-text, type-text

#let styles = _ => (render: label => [#label], align: left)

#let legend = gctx(
  "right",
  "colour",
  span: 10.0,
  text-style: styles,
  surface-stroke: _ => 0.5pt + black,
  place: (frac, across) => (frac * 10.0, -across),
)

// Arbitrary reservations for this fixture. They are the primitive's inputs,
// not a copy of what the renderer reserves: `prim-bar` measures whatever it is
// handed, and what the colour bar hands it is pinned by
// `tests/unit/test-colourbar-reserve.typ`.
#let V = (0.35, 3.0)
#let H = (3.0, 0.35)
#let LABEL-W = 0.8
#let V-LABEL-RESERVE = 0.3
#let V-PAD = 0.3
#let H-LABEL-BAND = 0.45

#let entry(value, frac) = (
  value: value,
  frac: frac,
  label: value,
  tier: "major",
)
#let ticks = (entry("0", 0.0), entry("5", 0.5), entry("10", 1.0))

// A vertical strip reserves its own height plus the pad below it, and its own
// width plus the gap and the widest label beside it.
#let vertical = prim-bar(
  entries: ticks,
  direction: "vertical",
  bar: V,
  band: V-PAD,
  label-reserve: V-LABEL-RESERVE + LABEL-W,
  label-w: LABEL-W,
)
#assert.eq(vertical.kind, PRIMITIVE)
#let v-box = registry.measure(vertical, legend)
#assert.eq(v-box.across, 3.0 + V-PAD)
#assert.eq(
  calc.round(v-box.along, digits: 9),
  calc.round(0.35 + V-LABEL-RESERVE + LABEL-W, digits: 9),
)

// A horizontal strip reserves the label band under it, and the widest label
// past its far end, which is the width the renderer has always kept.
#let horizontal = prim-bar(
  entries: ticks,
  direction: "horizontal",
  bar: H,
  band: H-LABEL-BAND,
  label-reserve: LABEL-W,
  label-w: LABEL-W,
)
#let h-box = registry.measure(horizontal, legend)
#assert.eq(calc.round(h-box.across, digits: 9), 0.8)
#assert.eq(calc.round(h-box.along, digits: 9), 3.8)

// A strip spans the length it was given rather than filling one, because a
// colour bar is a fixed box that the guide is sized from.
#assert.eq(v-box.fills, false)

// A strip with no box takes no room, ticks or not.
#assert.eq(
  registry.measure(prim-bar(entries: ticks, bar: (0.0, 0.0)), legend),
  measured(),
)

// Only the two directions the gizmo draws are accepted.
#assert.eq(DIRECTIONS, ("horizontal", "vertical"))
#assert.eq(
  enum-text("guide-bar", "direction", "sideways", DIRECTIONS),
  "guide-bar: direction must be one of \"horizontal\", \"vertical\"; got \"sideways\".",
)

// The box is a pair of centimetres, and every reserve is a length.
#assert.eq(
  type-text(
    "guide-bar",
    "bar",
    3.0,
    "a (width, height) pair in centimetres",
  ),
  "guide-bar: bar must be a (width, height) pair in centimetres; got 3.0.",
)
#assert.eq(
  error-text(
    "guide-bar",
    "band must be a number of centimetres of at least 0; got -1.0",
    hint: "The render stage resolves the strip's box before it gets here.",
  ),
  "guide-bar: band must be a number of centimetres of at least 0; got -1.0. The render stage resolves the strip's box before it gets here.",
)

// The strip lays itself out in centimetres, so a context with no span could
// only draw it at the near edge.
#assert.eq(
  error-text(
    "guide-bar",
    "the context spans none centimetres",
    hint: "A colour bar places itself in centimetres; pass `span:` on the "
      + "context it draws under.",
  ),
  "guide-bar: the context spans none centimetres. A colour bar places itself in centimetres; pass `span:` on the context it draws under.",
)

Guide-bar tests passed.
