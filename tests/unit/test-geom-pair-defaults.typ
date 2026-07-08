// Verify that bar/col/rect/polygon/label/boxplot now expose both `colour`
// and `fill` parameters, and that point/rect render correctly under the
// exclusive-default rule (only one of colour/fill set => the other gets no
// default).

#import "../../src/geom/bar.typ": geom-bar
#import "../../src/geom/col.typ": geom-col
#import "../../src/geom/rect.typ": geom-rect
#import "../../src/geom/polygon.typ": geom-polygon
#import "../../src/geom/label.typ": geom-label
#import "../../src/geom/boxplot.typ": geom-boxplot
#import "../../src/geom/point.typ": geom-point

// 1. Constructors expose both `colour` and `fill` defaulting to `auto`.
#for layer in (
  geom-bar(),
  geom-col(),
  geom-rect(),
  geom-polygon(),
  geom-label(),
  geom-boxplot(),
  geom-point(),
) {
  assert.eq(layer.params.fill, auto, message: layer.name + " fill")
  assert.eq(layer.params.colour, auto, message: layer.name + " colour")
}

// 2. Pinned values flow through to params.
#assert.eq(geom-rect(colour: rgb("#ff0000")).params.colour, rgb("#ff0000"))
#assert.eq(geom-col(colour: rgb("#00ff00")).params.colour, rgb("#00ff00"))
#assert.eq(geom-bar(colour: rgb("#0000ff")).params.colour, rgb("#0000ff"))
#assert.eq(geom-polygon(colour: rgb("#abcdef")).params.colour, rgb("#abcdef"))

// 3. End-to-end render: a `geom-rect` with `colour: red` and no `fill` should
// produce a stroked rect with no body fill (exclusive default rule). A
// `geom-rect` with `fill: blue` and no `colour` should produce a filled rect
// with no border. Smoke-render a panel of each via the resolver helpers
// directly, so we don't pull in the full plot pipeline here.

#import "../../src/utils/aes-pair.typ": resolve-pair-defaults

#let layer-of(params) = (name: "rect", params: params)
#let ink = rgb("#000000")
#let neutral = rgb("#4c78a8")

// Only colour pinned: fill default suppressed.
#assert.eq(
  resolve-pair-defaults(
    layer-of((colour: rgb("#ff0000"), fill: auto)),
    (:),
    ink,
    neutral,
  ),
  (ink, none),
)

// Only fill pinned: colour default suppressed.
#assert.eq(
  resolve-pair-defaults(
    layer-of((colour: auto, fill: rgb("#0000ff"))),
    (:),
    ink,
    neutral,
  ),
  (none, neutral),
)

// Mapped fill, no colour: still suppress colour default.
#assert.eq(
  resolve-pair-defaults(
    layer-of((colour: auto, fill: auto)),
    (fill: "k"),
    ink,
    neutral,
  ),
  (none, neutral),
)

geom pair-defaults tests passed.
