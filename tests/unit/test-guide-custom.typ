// guide-custom() builds a free-form guide spec consumed by the legend dispatch.

#import "../../src/guide/custom.typ": guide-custom
#import "../../src/guides.typ": guides

#let g = guide-custom([Hello])
#assert.eq(g.kind, "guide")
#assert.eq(g.name, "custom")
#assert.eq(g.width, auto)
#assert.eq(g.height, auto)
#assert.eq(g.title, none)
#assert.eq(g.placement.side, "right")
#assert.eq(g.placement.direction, "vertical")
#assert.eq(g.placement.order, none)
#assert.eq(g.placement.byrow, false)

#let sized = guide-custom(
  [Notes here],
  width: 4cm,
  height: 2cm,
  title: "Notes",
)
#assert.eq(sized.width, 4cm)
#assert.eq(sized.height, 2cm)
#assert.eq(sized.title, "Notes")

#let positioned = guide-custom(
  [Block],
  position: "bottom",
  order: 1,
)
#assert.eq(positioned.placement.side, "bottom")
#assert.eq(positioned.placement.direction, "horizontal")
#assert.eq(positioned.placement.order, 1)

#let hidden = guide-custom([], position: "none")
#assert.eq(hidden.placement.side, "none")

#let bound = guides(custom: guide-custom([x], width: 3cm))
#assert.eq(bound.custom.kind, "guide")
#assert.eq(bound.custom.name, "custom")
#assert.eq(bound.custom.width, 3cm)

Guide-custom tests passed.
