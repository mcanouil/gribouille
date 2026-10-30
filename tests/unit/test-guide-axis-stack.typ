// guide-axis-stack() builds a stacked spec consumed by either x or y axis.

#import "../../src/guide/axis.typ": guide-axis, guide-axis-logticks
#import "../../src/guide/axis-stack.typ": guide-axis-stack
#import "../../src/guides.typ": guides

#let g = guide-axis-stack((guide-axis(),))
#assert.eq(g.kind, "guide")
#assert.eq(g.stack, true)
#assert.eq(g.guides.len(), 1)
#assert.eq(g.spacing, 4pt)

#let stacked = guide-axis-stack(
  (guide-axis(angle: 30), guide-axis-logticks()),
  spacing: 8pt,
)
#assert.eq(stacked.guides.len(), 2)
#assert.eq(stacked.guides.at(0).angle, 30)
#assert.eq(stacked.guides.at(1).logticks, true)
#assert.eq(stacked.spacing, 8pt)

#let bound = guides(x: stacked)
#assert.eq(bound.x.stack, true)

Guide-axis-stack tests passed.
