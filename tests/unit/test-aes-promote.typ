// Promoted alpha and new linewidth aesthetics: spec shapes and training.

#import "../../src/scale/colour.typ": _alpha-continuous, _alpha-identity
#import "../../src/scale/linewidth.typ": (
  _linewidth-continuous, _linewidth-identity,
)
#import "../../src/scale/size.typ": _size-continuous, _size-identity
#import "../../lib.typ": scale-identity, scales
#import "../../src/scale/train.typ": train

// --- alpha scale specs ---

#let s-alpha-c = _alpha-continuous()
#assert.eq(s-alpha-c.kind, "scale")
#assert.eq(s-alpha-c.aesthetic, "alpha")
#assert.eq(s-alpha-c.type, "continuous")
#assert.eq(s-alpha-c.range, (0.1, 1))

#let s-alpha-c2 = _alpha-continuous(range: (0.2, 0.9))
#assert.eq(s-alpha-c2.range, (0.2, 0.9))

#let s-alpha-id = _alpha-identity()
#assert.eq(s-alpha-id.aesthetic, "alpha")
#assert.eq(s-alpha-id.type, "identity")

// --- linewidth scale specs ---

#let s-lw-c = _linewidth-continuous()
#assert.eq(s-lw-c.kind, "scale")
#assert.eq(s-lw-c.aesthetic, "linewidth")
#assert.eq(s-lw-c.type, "continuous")
#assert.eq(s-lw-c.range, (0.4pt, 1.4pt))

#let s-lw-c2 = _linewidth-continuous(range: (0.5pt, 2pt))
#assert.eq(s-lw-c2.range, (0.5pt, 2pt))

#let s-lw-id = _linewidth-identity()
#assert.eq(s-lw-id.aesthetic, "linewidth")
#assert.eq(s-lw-id.type, "identity")

// --- size scale specs ---

#let s-size-c = _size-continuous()
#assert.eq(s-size-c.kind, "scale")
#assert.eq(s-size-c.aesthetic, "size")
#assert.eq(s-size-c.type, "continuous")

#let s-size-id = _size-identity()
#assert.eq(s-size-id.aesthetic, "size")
#assert.eq(s-size-id.type, "identity")

// --- train() picks up alpha and linewidth on a mapped layer ---

#let layers = (
  (
    name: "point",
    mapping: (x: "x", y: "y", alpha: "w", linewidth: "w"),
    data: (
      (x: 0, y: 0, w: 1),
      (x: 1, y: 1, w: 5),
      (x: 2, y: 2, w: 9),
    ),
    inherit-aes: true,
  ),
)
#let trained = train(
  scales: (:),
  layers: layers,
  mapping: (x: "x", y: "y", alpha: "w", linewidth: "w"),
  data: none,
)
#assert.eq(trained.alpha.type, "continuous")
#assert.eq(trained.alpha.domain, (1.0, 9.0))
#assert.eq(trained.linewidth.type, "continuous")
#assert.eq(trained.linewidth.domain, (1.0, 9.0))

// --- identity scales bypass domain training ---

#let layers2 = (
  (
    name: "point",
    mapping: (x: "x", y: "y", alpha: "a"),
    data: (
      (x: 0, y: 0, a: 0.2),
      (x: 1, y: 1, a: 0.8),
    ),
    inherit-aes: true,
  ),
)
#let trained2 = train(
  scales: scales(alpha: scale-identity()),
  layers: layers2,
  mapping: (x: "x", y: "y", alpha: "a"),
  data: none,
)
#assert.eq(trained2.alpha.type, "identity")
#assert.eq(trained2.alpha.domain, ())

#let layers3 = (
  (
    name: "point",
    mapping: (x: "x", y: "y", size: "s"),
    data: (
      (x: 0, y: 0, s: 2pt),
      (x: 1, y: 1, s: 6pt),
    ),
    inherit-aes: true,
  ),
)
#let trained3 = train(
  scales: scales(size: scale-identity()),
  layers: layers3,
  mapping: (x: "x", y: "y", size: "s"),
  data: none,
)
#assert.eq(trained3.size.type, "identity")
#assert.eq(trained3.size.domain, ())

aes-promote tests passed.
