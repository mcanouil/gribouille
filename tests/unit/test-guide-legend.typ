// guide-legend(), guide-none(), and guides() build the expected dictionaries.

#import "../../src/guide/legend.typ": guide-legend
#import "../../src/guide/none.typ": guide-none
#import "../../src/guides.typ": guides
#import "../../src/legend.typ": _default-placement, _merge-placement

// `position` defaults to `auto` so an unset side inherits from
// `guides(default: ...)`; `direction` is likewise `auto` until the side is
// known.
#let g = guide-legend(reverse: true)
#assert.eq(g.kind, "guide")
#assert.eq(g.aesthetic, none)
#assert.eq(g.title, none)
#assert.eq(g.nrow, none)
#assert.eq(g.ncolumn, none)
#assert.eq(g.reverse, true)
#assert.eq(g.placement.side, auto)
#assert.eq(g.placement.align, none)
#assert.eq(g.placement.direction, auto)
#assert.eq(g.placement.order, none)
#assert.eq(g.placement.byrow, false)

// An explicit direction with no position keeps the side `auto`.
#let g-dir = guide-legend(direction: "horizontal")
#assert.eq(g-dir.placement.side, auto)
#assert.eq(g-dir.placement.direction, "horizontal")

#let g2 = guide-legend(title: "Group", ncolumn: 2)
#assert.eq(g2.title, "Group")
#assert.eq(g2.ncolumn, 2)
#assert.eq(g2.reverse, false)

#let g-top = guide-legend(position: "top")
#assert.eq(g-top.placement.side, "top")
#assert.eq(g-top.placement.direction, "horizontal")

#let g-bottom-vert = guide-legend(position: "bottom", direction: "vertical")
#assert.eq(g-bottom-vert.placement.side, "bottom")
#assert.eq(g-bottom-vert.placement.direction, "vertical")

#let g-inside = guide-legend(position: top + right)
#assert.eq(g-inside.placement.side, "inside")
#assert.eq(g-inside.placement.align, top + right)
#assert.eq(g-inside.placement.direction, "vertical")

#let g-offset = guide-legend(position: (dx: 1cm, dy: -2cm))
#assert.eq(g-offset.placement.side, "inside")
#assert.eq(g-offset.placement.align, top + left)
#assert.eq(g-offset.placement.dx, 1cm)
#assert.eq(g-offset.placement.dy, -2cm)

#let g-xy = guide-legend(position: (x: 70%, y: 30%))
#assert.eq(g-xy.placement.side, "inside")
#assert.eq(g-xy.placement.dx, 70%)
#assert.eq(g-xy.placement.dy, 30%)

#let g-none = guide-legend(position: "none")
#assert.eq(g-none.placement.side, "none")

#let g-order = guide-legend(order: 2, byrow: true)
#assert.eq(g-order.placement.order, 2)
#assert.eq(g-order.placement.byrow, true)

#let n = guide-none()
#assert.eq(n.kind, "guide")
#assert.eq(n.suppress, true)

#let bound = guides(colour: guide-legend(reverse: true), fill: guide-none())
#assert.eq(type(bound), dictionary)
#assert.eq(bound.colour.reverse, true)
#assert.eq(bound.fill.suppress, true)

// `guides()` stores a `default` fallback under its own key.
#let with-default = guides(default: guide-legend(position: "bottom"))
#assert.eq(with-default.default.placement.side, "bottom")

// `_merge-placement`: an `auto`-position override inherits side, corner, and
// offsets from the base; a direction override still applies; a concrete side
// replaces the placement.
#let base = (
  .._default-placement,
  side: "inside",
  align: top + right,
  dx: 1cm,
  dy: 2cm,
  direction: "horizontal",
)
#let merged-auto = _merge-placement(base, guide-legend(ncolumn: 2).placement)
#assert.eq(merged-auto.side, "inside")
#assert.eq(merged-auto.align, top + right)
#assert.eq(merged-auto.dx, 1cm)
#assert.eq(merged-auto.dy, 2cm)
#assert.eq(merged-auto.direction, "horizontal")

#let merged-dir = _merge-placement(
  base,
  guide-legend(direction: "vertical").placement,
)
#assert.eq(merged-dir.side, "inside")
#assert.eq(merged-dir.direction, "vertical")

#let merged-side = _merge-placement(
  base,
  guide-legend(position: "left").placement,
)
#assert.eq(merged-side.side, "left")

Guide-legend tests passed.
