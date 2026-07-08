// geom-ellipse smoke + axis-extension tests.

#import "../../src/geom/ellipse.typ": geom-ellipse
#import "../../src/scale/train.typ": train
#import "../../src/aes.typ": aes

// Constructor returns a layer dict with the documented defaults.
#let g = geom-ellipse()
#assert.eq(g.kind, "layer")
#assert.eq(g.name, "ellipse")
#assert.eq(g.stat, "identity")
#assert.eq(g.position, "identity")
#assert.eq(g.params.a, 1)
#assert.eq(g.params.b, 1)
#assert.eq(g.params.angle, 0)
#assert.eq(g.params.n, 64)
#assert.eq(g.params.alpha, auto)

// Layer params honour overrides.
#let g2 = geom-ellipse(a: 2, b: 0.5, angle: 1.0, n: 128, fill: red)
#assert.eq(g2.params.a, 2)
#assert.eq(g2.params.b, 0.5)
#assert.eq(g2.params.angle, 1.0)
#assert.eq(g2.params.n, 128)
#assert.eq(g2.params.fill, red)

// Train: x and y aren't mapped but the ellipse layer would extend axes via
// _post-train. Here we just verify train() does not require x/y mappings to
// register x0/y0/a/b/angle as aes-mapped columns when the layer has them.
#let d = (
  (x0: 0, y0: 0, a: 2, b: 1, angle: 0),
  (x0: 4, y0: 3, a: 1, b: 1, angle: 0),
)
#let m = aes(x0: "x0", y0: "y0", a: "a", b: "b", angle: "angle")
#let layer = geom-ellipse(mapping: m, data: d, inherit-aes: false)
// train() called with no plot-level mapping/data: the layer carries its own.
// x and y aren't mapped, so trained.x and trained.y stay absent at this stage.
#let trained = train(layers: (layer,), mapping: none, data: none)
#assert.eq(trained.at("x", default: none), none)
#assert.eq(trained.at("y", default: none), none)

geom-ellipse smoke tests passed.
