// coord-fixed: spec dictionary shape.

#import "../../src/coord/fixed.typ": coord-fixed

#let c1 = coord-fixed()
#assert.eq(c1.kind, "coord")
#assert.eq(c1.name, "fixed")
#assert.eq(c1.ratio, 1)

#let c2 = coord-fixed(ratio: 2)
#assert.eq(c2.name, "fixed")
#assert.eq(c2.ratio, 2)

#let c3 = coord-fixed(ratio: 0.5)
#assert.eq(c3.ratio, 0.5)

// The dict shape must stay stable so the faceted draw paths can read
// `ratio` and `coord` exactly like the non-faceted path.
#let keys-c1 = c1.keys().sorted()
#assert.eq(keys-c1, ("kind", "name", "ratio"))
#let keys-c2 = c2.keys().sorted()
#assert.eq(keys-c2, ("kind", "name", "ratio"))

coord-fixed tests passed.
