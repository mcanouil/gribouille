// Size-ladder key-glyph sizing: the legend reserves height and stride for the
// resolved `size` glyph so large markers never overlap the next key.

#import "../../src/legend.typ": (
  _GLYPH-DIAMETER-CM, _ladder-key-diam-cm, _ladder-vmetrics,
)

// Synthetic trained size scale mapping domain (0, 100) onto a radius range.
#let _size-trained(range) = (
  type: "continuous",
  domain: (0, 100),
  spec: (range: range),
)

// A `size` point ladder resolves a key diameter from the scale range that far
// exceeds the fixed swatch glyph.
#let wide = _ladder-key-diam-cm(
  _size-trained((3pt, 14pt)),
  (0, 50, 100),
  "point",
)
#assert(wide > _GLYPH-DIAMETER-CM)

// A narrow range stays within the fixed glyph and keeps the default diameter.
#assert.eq(
  _ladder-key-diam-cm(_size-trained((1pt, 2pt)), (0, 100), "point"),
  _GLYPH-DIAMETER-CM,
)

// No `size` scale (alpha/linewidth/stroke ladder) and non-point keys keep the
// fixed glyph diameter; their glyphs do not grow with the value.
#assert.eq(
  _ladder-key-diam-cm(none, (0, 100), "point"),
  _GLYPH-DIAMETER-CM,
)
#assert.eq(
  _ladder-key-diam-cm(_size-trained((3pt, 14pt)), (0, 100), "line"),
  _GLYPH-DIAMETER-CM,
)

// A wide glyph grows the row stride, the centring offset, and the last-row
// reservation; a fixed glyph reproduces the original base layout exactly.
#let mw = _ladder-vmetrics((key-diam-cm: wide), 9)
#let mn = _ladder-vmetrics((key-diam-cm: _GLYPH-DIAMETER-CM), 9)
#assert(mw.line-h > mn.line-h)
#assert(mw.last > mn.last)
#assert.eq(mw.off, wide / 2)
#assert.eq(mn.last, _GLYPH-DIAMETER-CM)

Size-ladder sizing tests passed.
