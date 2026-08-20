///! Blank depth, for aligning one guide against another.
///!
///! Draws nothing and reserves a fixed thickness. A stack uses it to line a
///! guide up with a neighbour that carries a part it does not.

#import "../../utils/errors.typ": check, fail-type
#import "common.typ": measured, primitive

#let prim-spacer(space) = {
  if type(space) not in (int, float) {
    fail-type("guide-spacer", "space", space, "a number of centimetres")
  }
  // A negative spacer would shrink the band a stack computes rather than pad
  // it, so it fails here rather than quietly eating a neighbour's room.
  check(
    space >= 0,
    "guide-spacer",
    "space cannot be negative; got " + repr(space),
    hint: "Use a positive number of centimetres, or drop the spacer.",
  )
  primitive("spacer", entries: (), space: space * 1.0)
}

#let measure(prim, gctx, entries: auto) = measured(across: prim.space)

// Blank by construction.
#let draw(prim, gctx, entries: auto) = {}
