// coord-transform: per-axis trans override at the coord stage.

#import "../../src/coord/transform.typ": coord-transform

#let c = coord-transform()
#assert.eq(c.kind, "coord")
#assert.eq(c.name, "transform")
#assert.eq(c.x, "identity")
#assert.eq(c.y, "identity")

#let c2 = coord-transform(x: "log10", y: "sqrt")
#assert.eq(c2.x, "log10")
#assert.eq(c2.y, "sqrt")

coord-transform tests passed.
