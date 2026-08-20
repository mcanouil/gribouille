///! The guide title.
///!
///! Ported from `_draw-title` in `render/legend.typ`, which pins a legend title
///! at one of three alignments across the guide's own width, and from the axis
///! title placement in `render/extents.typ`, which does the same along a panel
///! edge. The two differ only in which surface they read and which extent they
///! justify within, so one primitive covers both.
///!
///! As with labels, the text is measured by the render stage and stamped on the
///! primitive in cm, so this module needs no measurement context and the
///! reservation cannot drift from the ink.

#import "../../deps.typ": cetz
#import "../../utils/label-geometry.typ": _rotated-extent
#import "../gctx.typ": _axes-of
#import "../surface.typ": surface-for
#import "common.typ": NOTHING, measured, primitive

// Where a title sits across the guide it labels.
#let ALIGNMENTS = (left, center, right)

#let prim-title(body, angle: 0, align: none, extent: (0.0, 0.0)) = primitive(
  "title",
  entries: (),
  body: body,
  angle: angle,
  align: align,
  extent: extent,
)

// A title is as deep as its turned box, and as long as that box reads.
#let measure(prim, gctx, entries: auto) = {
  if prim.at("body", default: none) == none { return NOTHING }
  if surface-for(gctx, "title") == none { return NOTHING }
  let (w, h) = prim.at("extent", default: (0.0, 0.0))
  if w == 0.0 and h == 0.0 { return NOTHING }
  let turned = _rotated-extent(w, h, prim.at("angle", default: 0))
  let axes = if gctx.position in ("theta", "r") { none } else {
    _axes-of(gctx.position)
  }
  if axes == none or axes.along == "x" {
    measured(across: turned.height, along: turned.width)
  } else {
    measured(across: turned.width, along: turned.height)
  }
}

// The point along the guide a title is pinned at, and the cetz anchor that
// pins it there. Mirrors `_draw-title`: left-aligned at the near edge, centred
// at the middle, right-aligned at the far edge.
#let _pin-for(a, axes) = {
  let vertical = axes != none and axes.along == "y"
  if a == right {
    (1.0, if vertical { "north" } else { "north-east" })
  } else if a == center {
    (0.5, if vertical { "center" } else { "north" })
  } else {
    (0.0, if vertical { "south" } else { "north-west" })
  }
}

#let draw(prim, gctx, entries: auto) = {
  let body = prim.at("body", default: none)
  if body == none { return }
  let surface = surface-for(gctx, "title")
  if surface == none { return }
  let place = gctx.place
  if place == none { return }
  let styles = gctx.at("text-style", default: none)
  if styles == none { return }
  let style = (styles)(surface)
  let a = prim.at("align", default: none)
  let resolved = if a == none { style.at("align", default: left) } else { a }
  let axes = if gctx.position in ("theta", "r") { none } else {
    _axes-of(gctx.position)
  }
  let (frac, anchor) = _pin-for(
    if resolved == none { left } else { resolved },
    axes,
  )
  cetz.draw.content(
    place(frac, 0.0),
    (style.render)(body),
    anchor: anchor,
    angle: prim.at("angle", default: 0) * 1deg,
  )
}
