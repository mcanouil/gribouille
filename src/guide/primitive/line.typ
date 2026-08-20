///! The guide spine: the line an axis draws along its own edge.
///!
///! Ported from the two axis-line draw sites in `render/panel-draw.typ`, which
///! draw one segment along each primary edge.
///!
///! The line sits on the panel edge rather than beside it, so it reserves no
///! depth. A legend has no line surface at all, so there it draws nothing and
///! measures nothing, which is the asymmetry `surface-for` encodes.
///!
///! A swept spine is not here. The theta arc has its own sampling policy in
///! `radial-arc` and its own cap trimming, and reproducing either badly would
///! regress a capped radial axis; the radial composition brings both.

#import "../../deps.typ": cetz
#import "../surface.typ": surface-for
#import "common.typ": NOTHING, measured, primitive, stroke-for

#let prim-line() = primitive("line", entries: auto)

// A spine runs the length of the guide and adds no thickness to the band. A
// blanked surface draws nothing, so it measures nothing either: measure and
// draw gate on the same stroke.
#let measure(prim, gctx, entries: auto) = {
  if stroke-for(gctx, surface-for(gctx, "line")) == none { return NOTHING }
  measured(along: 1.0)
}

#let draw(prim, gctx, entries: auto) = {
  let stroke = stroke-for(gctx, surface-for(gctx, "line"))
  if stroke == none { return }
  let place = gctx.place
  if place == none { return }
  cetz.draw.line(place(0.0, 0.0), place(1.0, 0.0), stroke: stroke)
}
