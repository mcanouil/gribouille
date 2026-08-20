///! What every guide primitive returns, and the guards they share.
///!
///! A primitive exports two functions with fixed shapes:
///!
///! - `measure(prim, gctx)` answers how much room it needs, as a `measured`
///!   record. `across` is its thickness growing away from the panel, `along` is
///!   its extent in the direction the guide reads, and `reach` is how far it
///!   overhangs each end of that extent. `reach` is not derivable from the other
///!   two: a rotated corner-pinned label swings about its pin, so the chrome
///!   stage floors the margin on it separately.
///! - `draw(prim, gctx)` emits cetz and returns nothing. It places ink through
///!   `gctx.place` alone, never from a side of its own, which is what lets one
///!   primitive serve four sides, a legend, and the radial sweep.

#import "../../utils/errors.typ": fail-enum
#import "../entry.typ": check-entries

// The shape every `measure` returns.
#let measured(across: 0.0, along: 0.0, near: 0.0, far: 0.0) = (
  across: across,
  along: along,
  reach: (near: near, far: far),
)

// A primitive that draws nothing takes no room.
#let NOTHING = measured()

// Tag every primitive carries, so a composition can tell one from a nested
// composition without knowing the primitive names.
#let PRIMITIVE = "primitive"

#let primitive(name, ..fields) = (
  kind: PRIMITIVE,
  name: name,
  ..fields.named(),
)

// A tick is worth drawing only when it has both a stroke and a length. Mirrors
// `_should-draw-tick` in `render/common.typ`, which the axis draw has always
// gated on.
#let draws-tick(stroke, len) = stroke != none and len > 0

// Resolve the entries a primitive draws: its own when it declares any, the
// parent composition's when it left them `auto`.
//
// This is the boundary between the builder that produced the table and the
// primitive that consumes it, so the table is checked here. An untrained row
// would otherwise reach `place` and panic on `none * float`, which is the
// failure the check exists to replace.
#let entries-of(prim, inherited, scope: "guide-primitive") = {
  let own = prim.at("entries", default: auto)
  let rows = if own != auto { own } else if (
    inherited == auto or inherited == none
  ) { () } else { inherited }
  if rows.len() == 0 { return () }
  check-entries(rows, scope)
}

// Guard a tier name where it is supplied, so a typo names the primitive rather
// than silently drawing an empty guide.
#let check-tier(tier, valid, scope) = {
  if not valid.contains(tier) {
    fail-enum(scope, "tier", tier, valid)
  }
  tier
}

// The stroke a surface resolves to, through the closure the context carries.
// `none` when the context cannot resolve strokes, or when the theme blanked it.
#let stroke-for(gctx, surface) = {
  if surface == none { return none }
  let resolve = gctx.at("surface-stroke", default: none)
  if resolve == none { return none }
  (resolve)(surface)
}
