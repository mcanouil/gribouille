///! Blank depth, for aligning one guide against another.
///!
///! Draws nothing and reserves a fixed thickness. A stack uses it to line a
///! guide up with a neighbour that carries a part it does not.

#import "../../utils/errors.typ": fail-type
#import "common.typ": measured, primitive

#let prim-spacer(space) = {
  if type(space) not in (int, float) {
    fail-type("guide-spacer", "space", space, "a number of centimetres")
  }
  primitive("spacer", entries: (), space: space * 1.0)
}

#let measure(prim, gctx, entries: auto) = measured(across: prim.space)

// Blank by construction.
#let draw(prim, gctx, entries: auto) = {}
