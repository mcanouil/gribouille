// Rotated-label geometry, moved out of `render/extents.typ` so the guide
// primitives and the chrome stage read one copy. Pins the moved behaviour and
// the re-export the chrome stage still imports through.

#import "../../src/utils/label-geometry.typ": (
  _ANCHOR-OFFSET, _label-reach, _rotated-extent, _x-label-anchor,
)
#import "../../src/render/extents.typ" as extents

// The anchor an x tick label is pinned at, by rotation sense.
#assert.eq(_x-label-anchor(0), "north")
#assert.eq(_x-label-anchor(30), "north-east")
#assert.eq(_x-label-anchor(-30), "north-west")

#assert.eq(_ANCHOR-OFFSET.center, (0, 0))
#assert.eq(_ANCHOR-OFFSET.north, (0, 1))

// A centre-anchored label reaches half its box each way, so the bounding box of
// an unturned 2cm by 1cm label is the label.
#let flat = _rotated-extent(2.0, 1.0, 0)
#assert.eq(calc.round(flat.width, digits: 6), 2.0)
#assert.eq(calc.round(flat.height, digits: 6), 1.0)

// A quarter turn swaps the two extents.
#let turned = _rotated-extent(2.0, 1.0, 90)
#assert.eq(calc.round(turned.width, digits: 6), 1.0)
#assert.eq(calc.round(turned.height, digits: 6), 2.0)

// Past a quarter turn the box is as big as its mirror in the first quadrant,
// rather than folding back towards nothing.
#let past = _rotated-extent(2.0, 1.0, 135)
#let mirror = _rotated-extent(2.0, 1.0, 45)
#assert.eq(calc.round(past.width, digits: 6), calc.round(
  mirror.width,
  digits: 6,
))
#assert.eq(
  calc.round(past.height, digits: 6),
  calc.round(mirror.height, digits: 6),
)

// A `north`-anchored 2cm by 1cm label at angle 0 hangs entirely below its pin:
// half its width each way, its full height down, nothing up.
#let hung = _label-reach(2.0, 1.0, 0, "north")
#assert.eq(calc.round(hung.right, digits: 6), 1.0)
#assert.eq(calc.round(hung.left, digits: 6), 1.0)
#assert.eq(calc.round(hung.up, digits: 6), 0.0)
#assert.eq(calc.round(hung.down, digits: 6), 1.0)

// The move is behaviour-preserving: the re-export the chrome stage imports
// through is the same function.
#assert.eq(extents._rotated-extent(2.0, 1.0, 90), turned)
#assert.eq(extents._label-reach(2.0, 1.0, 0, "north"), hung)
#assert.eq(extents._x-label-anchor(30), "north-east")

Label-geometry tests passed.
