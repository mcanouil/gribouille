// Size-ladder key-glyph sizing: the legend reserves height and stride for the
// resolved `size` glyph so large markers never overlap the next key.

#import "../../src/legend.typ": (
  _GLYPH-DIAMETER-CM, _guide-shape, _ladder-key-diam-cm, _ladder-vmetrics,
  _size-ladder-height,
)

// A size-ladder's grid shape uses its break count under nrow/ncolumn.
#let _ladder-shape(guide) = _guide-shape(guide, guide.breaks.len())

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

// A size ladder honours `nrow`/`ncolumn` the same way the swatch does: the
// breaks wrap into a grid instead of one row (horizontal) or column (vertical).
#let _ladder(direction, breaks, nrow: none, ncolumn: none) = (
  kind: "size-ladder",
  title: none,
  breaks: breaks,
  nrow: nrow,
  ncolumn: ncolumn,
  placement: (direction: direction, byrow: false),
)

// Default shapes: horizontal is one row, vertical one column.
#assert.eq(_ladder-shape(_ladder("horizontal", (1, 2, 3, 4))), (
  rows: 1,
  cols: 4,
))
#assert.eq(_ladder-shape(_ladder("vertical", (1, 2, 3, 4))), (rows: 4, cols: 1))

// `nrow`/`ncolumn` reshape the grid.
#assert.eq(
  _ladder-shape(_ladder("horizontal", (1, 2, 3, 4), nrow: 2)),
  (rows: 2, cols: 2),
)
#assert.eq(
  _ladder-shape(_ladder("vertical", (1, 2, 3, 4), ncolumn: 2)),
  (rows: 2, cols: 2),
)

// A two-column vertical ladder reserves less height than the single column it
// wraps from; a two-row horizontal ladder reserves more than one row.
#assert(
  _size-ladder-height(_ladder("vertical", (1, 2, 3, 4), ncolumn: 2), 0, 9)
    < _size-ladder-height(_ladder("vertical", (1, 2, 3, 4)), 0, 9),
)
#assert(
  _size-ladder-height(_ladder("horizontal", (1, 2, 3, 4), nrow: 2), 0, 9)
    > _size-ladder-height(_ladder("horizontal", (1, 2, 3, 4)), 0, 9),
)

Size-ladder sizing tests passed.
