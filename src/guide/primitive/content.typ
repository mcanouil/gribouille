///! An opaque block of Typst content.
///!
///! What `guide-custom` carries: markup, an image, a table, anything Typst can
///! typeset. The layer cannot look inside it, so the block reserves the size it
///! was given and draws at that size.
///!
///! Ported from the custom-guide draw in `render/legend.typ`, which boxes the
///! content and anchors it at the top-left corner of its slot.

#import "../../deps.typ": cetz
#import "../../utils/errors.typ": check
#import "common.typ": NOTHING, measured, primitive

// Footprint a custom block takes when the user named neither dimension. Two
// legend columns wide, so it sits beside the standard legends without forcing
// the page to grow.
#let DEFAULT-WIDTH = 3.0
#let DEFAULT-HEIGHT = 2.0

#let prim-content(body, width: DEFAULT-WIDTH, height: DEFAULT-HEIGHT) = {
  for (name, value) in (("width", width), ("height", height)) {
    check(
      type(value) in (int, float) and value >= 0,
      "guide-content",
      name
        + " must be a number of centimetres of at least 0; got "
        + repr(value),
      hint: "The guide builder resolves a length or `auto` before it gets here.",
    )
  }
  primitive(
    "content",
    entries: (),
    body: body,
    width: width * 1.0,
    height: height * 1.0,
  )
}

// The block is opaque, so it takes exactly the room it was given. Depth runs
// along whichever canvas axis the context says `across` runs along: downward in
// a legend box, away from the edge on an axis.
#let measure(prim, gctx, entries: auto) = {
  if prim.at("body", default: none) == none { return NOTHING }
  let (w, h) = (prim.width, prim.height)
  if w == 0.0 or h == 0.0 { return NOTHING }
  if gctx.axes.along == "x" {
    measured(across: h, along: w)
  } else {
    measured(across: w, along: h)
  }
}

#let draw(prim, gctx, entries: auto) = {
  let body = prim.at("body", default: none)
  if body == none { return }
  let place = gctx.at("place", default: none)
  if place == none { return }
  cetz.draw.content(
    place(0.0, 0.0),
    box(width: prim.width * 1cm, height: prim.height * 1cm, body),
    anchor: "north-west",
  )
}
