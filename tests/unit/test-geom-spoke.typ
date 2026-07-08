// geom-spoke smoke tests.

#import "../../src/geom/spoke.typ": geom-spoke

#let g = geom-spoke()
#assert.eq(g.kind, "layer")
#assert.eq(g.name, "spoke")
#assert.eq(g.stat, "identity")
#assert.eq(g.position, "identity")
#assert.eq(g.params.angle, 0deg)
#assert.eq(g.params.radius, 1)
#assert.eq(g.params.linetype, auto)
#assert.eq(g.params.stroke, auto)

#let g2 = geom-spoke(angle: 45deg, radius: 2, stroke: 1pt, colour: red)
#assert.eq(g2.params.angle, 45deg)
#assert.eq(g2.params.radius, 2)
#assert.eq(g2.params.stroke, 1pt)
#assert.eq(g2.params.colour, red)

geom-spoke smoke tests passed.
