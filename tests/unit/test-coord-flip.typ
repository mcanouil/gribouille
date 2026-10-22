// coord-flip: spec dictionary shape and renderer detection.

#import "../../src/coord/flip.typ": coord-flip
#import "../../src/render/domain.typ": _apply-flip, _flip-mapping, _is-flipped
#import "../../src/utils/flip.typ": (
  range-axes, range-canvas-point, range-columns, range-stair-direction,
)

#let c1 = coord-flip()
#assert.eq(c1.kind, "coord")
#assert.eq(c1.name, "flip")
#assert.eq(c1.reverse, auto)

// The dict shape must stay stable so the renderer can route the spec into
// the flip swap without touching positional or fixed-aspect coords.
#let keys-c1 = c1.keys().sorted()
#assert.eq(keys-c1, ("kind", "name", "reverse"))

// Explicit reverse values carry through the spec.
#assert.eq(coord-flip(reverse: true).reverse, true)
#assert.eq(coord-flip(reverse: false).reverse, false)

// `_is-flipped` recognises the flip coord and rejects everything else.
#assert.eq(_is-flipped(c1), true)
#assert.eq(_is-flipped((kind: "coord", coord: "cartesian")), false)
#assert.eq(_is-flipped((kind: "coord", coord: "fixed", ratio: 1)), false)
#assert.eq(_is-flipped(none), false)

// `_apply-flip` swaps trained.x and trained.y when the coord is flip,
// and is a no-op otherwise.
#let trained = (
  x: (type: "discrete", domain: ("a", "b", "c")),
  y: (type: "continuous", domain: (0, 10)),
)
#let flipped = _apply-flip(trained, c1)
#assert.eq(flipped.x.type, "continuous")
#assert.eq(flipped.x.domain, (0, 10))
#assert.eq(flipped.y.type, "discrete")
#assert.eq(flipped.y.domain, ("a", "b", "c"))
// Default `auto` policy reverses a discrete post-flip y.
#assert.eq(flipped.y.reverse, true)

// `reverse: false` opts out even when post-flip y is discrete.
#let opt-out = _apply-flip(trained, coord-flip(reverse: false))
#assert.eq(opt-out.y.at("reverse", default: false), false)

// Continuous x flipped to continuous y under default `auto` stays put.
#let cc = (
  x: (type: "continuous", domain: (0, 10)),
  y: (type: "continuous", domain: (0, 1)),
)
#let cc-flipped = _apply-flip(cc, c1)
#assert.eq(cc-flipped.y.at("transform", default: "identity"), "identity")

// Explicit `reverse: true` reverses a continuous post-flip y via a `reverse`
// flag, leaving any numeric transform intact.
#let cc-rev = _apply-flip(cc, coord-flip(reverse: true))
#assert.eq(cc-rev.y.reverse, true)
#assert.eq(cc-rev.y.at("transform", default: "identity"), "identity")

// A log10 x keeps its transform under flip + reverse (regression: the
// reverse used to overwrite the numeric transform with "reverse").
#let cc-log = (
  x: (type: "continuous", domain: (0, 3), transform: "log10"),
  y: (type: "continuous", domain: (0, 1)),
)
#let cc-log-rev = _apply-flip(cc-log, coord-flip(reverse: true))
#assert.eq(cc-log-rev.y.transform, "log10")
#assert.eq(cc-log-rev.y.reverse, true)

#let untouched = _apply-flip(trained, (kind: "coord", coord: "cartesian"))
#assert.eq(untouched.x.type, "discrete")
#assert.eq(untouched.y.type, "continuous")

// `_flip-mapping` moves every positional pair onto the swapped trained axes,
// so a segment end follows its start.
#assert.eq(
  _flip-mapping((x: "a", y: "b", xend: "c", yend: "d", colour: "k")),
  (x: "b", y: "a", xend: "d", yend: "c", colour: "k"),
)
// The range channels swap too, so a rectangle follows the trained axes.
#assert.eq(
  _flip-mapping((xmin: "a", xmax: "b", ymin: "c", ymax: "d")),
  (xmin: "c", xmax: "d", ymin: "a", ymax: "b"),
)
// A pair with one side unmapped moves that side across and leaves no key, so
// a geom reading the empty side with `default:` still gets its default.
#assert.eq(_flip-mapping((x: "a", xend: "c")), (y: "a", yend: "c"))
#assert.eq(_flip-mapping((colour: "k")), (colour: "k"))
// A key that `aes()` holds as `none` stays present on the other side, so a
// geom that reads `mapping.x` directly still finds the key.
#assert.eq(_flip-mapping((x: "a", y: none)), (x: none, y: "a"))
#assert.eq(_flip-mapping(none), none)

// A range geom reads its position and range from the keys the flip swap
// moved them to, so a flipped errorbar-like mapping still resolves.
#let range-aes = (x: "g", y: "v", ymin: "lo", ymax: "hi")
#assert.eq(
  range-columns(range-aes, false),
  (pos: "g", value: "v", min: "lo", max: "hi"),
)
#assert.eq(
  range-columns(_flip-mapping(range-aes), true),
  (pos: "g", value: "v", min: "lo", max: "hi"),
)
#assert.eq(
  range-columns((x: "g"), false),
  (pos: "g", value: none, min: none, max: none),
)

// The position axis takes the trained y scale and the vertical canvas range
// under flip.
#let axes-ctx = (
  trained: (x: "tx", y: "ty"),
  px-range: (0, 10),
  py-range: (0, 5),
)
#assert.eq(
  range-axes(axes-ctx + (flipped: true)),
  (
    pos-trained: "ty",
    value-trained: "tx",
    pos-range: (0, 5),
    value-range: (0, 10),
  ),
)
#assert.eq(
  range-axes(axes-ctx),
  (
    pos-trained: "tx",
    value-trained: "ty",
    pos-range: (0, 10),
    value-range: (0, 5),
  ),
)
#assert.eq(range-axes(axes-ctx + (trained: (x: "tx"))), none)

#assert.eq(range-canvas-point(false, 1, 2), (1, 2))
#assert.eq(range-canvas-point(true, 1, 2), (2, 1))

// A step along the position axis turns into the other corner order once
// that axis is vertical.
#assert.eq(range-stair-direction("hv", false), "hv")
#assert.eq(range-stair-direction("hv", true), "vh")
#assert.eq(range-stair-direction("vh", true), "hv")
#assert.eq(range-stair-direction(none, true), none)

coord-flip tests passed.
