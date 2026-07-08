// Swatch legend key glyph size: `guide-legend(key-size:)` overrides the themed
// base diameter, the resolved diameter lands on the guide record, and the
// reserved width / height grow with it so reserve tracks draw. Size-ladder
// legends ignore the override (their glyph encodes the `size` scale).

#import "../../src/guide/legend.typ": guide-legend
#import "../../src/render/legend.typ": (
  _row-stack-height, _swatch-key-diam-cm, _swatch-lead-cm, _swatch-line-h-cm,
  _swatch-stride-cm, guides-for,
)

// Helper: a per-legend `key-size` length wins; `none` defers to the themed base.
#assert.eq(_swatch-key-diam-cm(0.5cm, 0.24), 0.5)
#assert.eq(_swatch-key-diam-cm(none, 0.24), 0.24)
#assert.eq(_swatch-key-diam-cm(none, 0.4), 0.4)

#let trained = (colour: (type: "discrete", domain: ("a", "b")))
#let spec(g) = (
  mapping: (colour: "g"),
  layers: (
    (
      geom: "point",
      mapping: none,
      inherit-aes: true,
      params: (colour: auto, fill: auto, shape: auto),
    ),
  ),
  guides: g,
)

// Default: the guide takes the themed base diameter (0.24cm fallback).
#let g-default = guides-for(spec((:)), trained)
#assert.eq(g-default.at(0).kind, "swatch")
#assert.eq(g-default.at(0).key-diam-cm, 0.24)

// A themed base (passed as `key-diam-cm`) flows through when `key-size` is unset.
#let g-theme = guides-for(spec((:)), trained, key-diam-cm: 0.4)
#assert.eq(g-theme.at(0).key-diam-cm, 0.4)

// A per-legend `key-size` wins over the themed base.
#let g-key = guides-for(
  spec((colour: guide-legend(key-size: 0.5cm))),
  trained,
  key-diam-cm: 0.4,
)
#assert.eq(g-key.at(0).key-diam-cm, 0.5)

// Reserve tracks draw: a wider glyph widens the lead and the row stack.
#assert(_swatch-lead-cm(0.5, 9) > _swatch-lead-cm(0.24, 9))
#assert(
  _row-stack-height(3, 0.4, 9, 0.5) > _row-stack-height(3, 0.4, 9, 0.24),
)

// The row stride grows past the glyph so stacked glyphs never overlap; a small
// glyph keeps the font-derived line height.
#assert(_swatch-stride-cm(0.6, 9) >= 0.6)
#assert.eq(_swatch-stride-cm(0.1, 9), _swatch-line-h-cm(9))

// A size-ladder ignores `key-size`: its diameter is driven only by the `size`
// scale, so the override leaves it identical to a ladder without `key-size`.
#let ladder-spec(g) = (
  mapping: (size: "g"),
  layers: (
    (
      geom: "point",
      mapping: none,
      inherit-aes: true,
      params: (size: auto),
    ),
  ),
  guides: g,
)
#let ladder-trained = (
  size: (type: "continuous", domain: (1.0, 5.0), spec: (range: (2pt, 4pt))),
)
#let ladder = guides-for(
  ladder-spec((size: guide-legend(key-size: 0.5cm))),
  ladder-trained,
)
#let ladder-plain = guides-for(ladder-spec((:)), ladder-trained)
#assert.eq(ladder.at(0).kind, "size-ladder")
#assert.eq(ladder.at(0).key-diam-cm, ladder-plain.at(0).key-diam-cm)

#text("Legend key-size tests passed.")
