///! The guide spine: the axis line, or the arc a radial axis draws.
///!
///! Ported from the two axis-line draw sites in `render/panel-draw.typ`, which
///! draw one segment along each primary edge.
///!
///! The line sits on the panel edge rather than beside it, so it reserves no
///! depth. A legend has no line surface at all, so there it draws nothing and
///! measures nothing, which is the asymmetry `surface-for` encodes.

#import "../../deps.typ": cetz
#import "../surface.typ": surface-for
#import "common.typ": NOTHING, measured, primitive

// Samples along a swept spine. A theta axis draws an arc, which cetz renders as
// a polyline, so the spine is sampled rather than drawn as one segment.
#let _ARC-STEPS = 64

#let prim-line() = primitive("line", entries: auto)

// A spine runs the length of the guide and adds no thickness to the band.
#let measure(prim, gctx, entries: auto) = {
  if surface-for(gctx, "line") == none { return NOTHING }
  measured(along: 1.0)
}

#let draw(prim, gctx, entries: auto) = {
  let surface = surface-for(gctx, "line")
  if surface == none { return }
  let resolve = gctx.at("surface-stroke", default: none)
  let stroke = if resolve == none { none } else { (resolve)(surface) }
  if stroke == none { return }
  let place = gctx.place
  if place == none { return }
  if gctx.position == "theta" {
    cetz.draw.line(
      ..range(_ARC-STEPS + 1).map(i => place(i / _ARC-STEPS, 0.0)),
      stroke: stroke,
    )
  } else {
    cetz.draw.line(place(0.0, 0.0), place(1.0, 0.0), stroke: stroke)
  }
}
