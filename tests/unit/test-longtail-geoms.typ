// Smoke tests for the long-tail geoms: blank, rug, function.
// Each constructor must return a layer dict with the documented defaults.

#import "../../src/geom/blank.typ": geom-blank
#import "../../src/geom/rug.typ": geom-rug
#import "../../src/geom/function.typ": geom-function

#let bl = geom-blank()
#assert.eq(bl.kind, "layer")
#assert.eq(bl.geom, "blank")
#assert.eq(bl.stat, "identity")
#assert.eq(bl.position, "identity")
#assert.eq(bl.mapping, none)
#assert.eq(bl.data, none)
#assert.eq(bl.inherit-aes, true)

#let rg = geom-rug()
#assert.eq(rg.kind, "layer")
#assert.eq(rg.geom, "rug")
#assert.eq(rg.stat, "identity")
#assert.eq(rg.position, "identity")
#assert.eq(rg.params.sides, "bl")
#assert.eq(rg.params.length, 0.15cm)
#assert.eq(rg.params.alpha, auto)

#let rg2 = geom-rug(sides: "tr", length: 0.25cm, colour: red, alpha: 0.5)
#assert.eq(rg2.params.sides, "tr")
#assert.eq(rg2.params.length, 0.25cm)
#assert.eq(rg2.params.colour, red)
#assert.eq(rg2.params.alpha, 0.5)

#let fn = geom-function(fun: x => x)
#assert.eq(fn.kind, "layer")
#assert.eq(fn.geom, "function")
#assert.eq(fn.stat, "identity")
#assert.eq(fn.position, "identity")
#assert.eq(fn.params.n, 101)
#assert.eq(fn.params.x-limits, none)
#assert.eq(fn.params.linetype, "solid")
#assert.eq(fn.inherit-aes, false)
#assert.eq(fn.data, ())

#let fn2 = geom-function(
  fun: x => calc.sin(x),
  n: 50,
  x-limits: (-1, 1),
)
#assert.eq(fn2.params.n, 50)
#assert.eq(fn2.params.x-limits, (-1, 1))

Long-tail geom smoke tests passed.
