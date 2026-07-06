// Okabe-Ito palette + default discrete scale unit tests.

#import "../../src/utils/palette.typ": default-discrete, okabe-ito
#import "../../src/scale/colour.typ": _scale-okabe-ito

// Canonical 8-colour Okabe-Ito ordering (Wong 2011, Nature Methods).
#assert.eq(okabe-ito.len(), 8)
#assert.eq(okabe-ito.at(0), rgb("#e69f00"))
#assert.eq(okabe-ito.at(1), rgb("#56b4e9"))
#assert.eq(okabe-ito.at(2), rgb("#009e73"))
#assert.eq(okabe-ito.at(3), rgb("#f0e442"))
#assert.eq(okabe-ito.at(4), rgb("#0072b2"))
#assert.eq(okabe-ito.at(5), rgb("#d55e00"))
#assert.eq(okabe-ito.at(6), rgb("#cc79a7"))
#assert.eq(okabe-ito.at(7), rgb("#999999"))

// Okabe-Ito is the library default for unmapped discrete aesthetics.
#assert.eq(default-discrete, okabe-ito)

// scale-okabe-ito carries the palette and aesthetic.
#let sc = _scale-okabe-ito("colour")
#assert.eq(sc.kind, "scale")
#assert.eq(sc.aesthetic, "colour")
#assert.eq(sc.type, "discrete")
#assert.eq(sc.palette, okabe-ito)
#assert.eq(sc.name, none)
#assert.eq(sc.limits, none)
#assert.eq(sc.labels, auto)

// scale-okabe-ito mirrors the colour twin with aesthetic "fill".
#let sf = _scale-okabe-ito("fill", name: "Group", limits: ("a", "b", "c"))
#assert.eq(sf.aesthetic, "fill")
#assert.eq(sf.type, "discrete")
#assert.eq(sf.palette, okabe-ito)
#assert.eq(sf.name, "Group")
#assert.eq(sf.limits, ("a", "b", "c"))
