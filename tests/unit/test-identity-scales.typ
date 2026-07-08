// Identity scale specs and training.

#import "../../src/scale/colour.typ": _scale-identity
#import "../../src/scale/shape.typ": _shape-identity
#import "../../src/scale/linetype.typ": _linetype-identity
#import "../../lib.typ": scale-identity, scales
#import "../../src/scale/train.typ": train

// --- spec dicts carry type "identity" and the right aesthetic ---

#let s-colour = _scale-identity("colour")
#assert.eq(s-colour.kind, "scale")
#assert.eq(s-colour.aesthetic, "colour")
#assert.eq(s-colour.type, "identity")

#let s-fill = _scale-identity("fill")
#assert.eq(s-fill.aesthetic, "fill")
#assert.eq(s-fill.type, "identity")

#let s-shape = _shape-identity()
#assert.eq(s-shape.aesthetic, "shape")
#assert.eq(s-shape.type, "identity")

#let s-linetype = _linetype-identity()
#assert.eq(s-linetype.aesthetic, "linetype")
#assert.eq(s-linetype.type, "identity")

// --- train() returns identity scales without computing a domain ---

#let layers = (
  (
    name: "point",
    mapping: (x: "x", y: "y", colour: "c"),
    data: (
      (x: 0, y: 0, c: "#1b9e77"),
      (x: 1, y: 1, c: "#d95f02"),
    ),
    inherit-aes: true,
  ),
)
#let trained = train(
  scales: scales(colour: scale-identity()),
  layers: layers,
  mapping: (x: "x", y: "y", colour: "c"),
  data: none,
)
#assert.eq(trained.colour.type, "identity")
#assert.eq(trained.colour.domain, ())

Identity scales tests passed.
