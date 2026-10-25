// coord-flip: spec dictionary shape and renderer detection.

#import "../../src/coord/cartesian.typ": coord-cartesian
#import "../../src/coord/fixed.typ": coord-fixed
#import "../../src/coord/flip.typ": coord-flip
#import "../../src/coord/resolve.typ": resolve-coord
#import "../../src/render/domain.typ": _flip-mapping
#import "../../src/utils/flip.typ": (
  user-axes, user-columns, user-point, user-stair-direction,
)

#let c1 = coord-flip()
#assert.eq(c1.kind, "coord")
#assert.eq(c1.name, "flip")
#assert.eq(c1.reverse, auto)

// The dict shape must stay stable so the renderer can route the spec into
// the flip swap without touching positional or fixed-aspect coords.
#let keys-c1 = c1.keys().sorted()
#assert.eq(
  keys-c1,
  (
    "axis-range",
    "flipped",
    "frame",
    "kind",
    "name",
    "panel-size",
    "project",
    "reverse",
    "to-canvas",
    "train",
  ),
)

// Explicit reverse values carry through the spec.
#assert.eq(coord-flip(reverse: true).reverse, true)
#assert.eq(coord-flip(reverse: false).reverse, false)

// `flipped` marks the flip coord and no other.
#assert.eq(c1.flipped, true)
#assert.eq(coord-cartesian().flipped, false)
#assert.eq(coord-fixed(ratio: 1).flipped, false)
#assert.eq(resolve-coord(none).flipped, false)

// The flip `train` swaps trained.x and trained.y, and the other coords leave
// them in place.
#let trained = (
  x: (type: "discrete", domain: ("a", "b", "c")),
  y: (type: "continuous", domain: (0, 10)),
)
#let flipped = (c1.train)(trained)
#assert.eq(flipped.x.type, "continuous")
#assert.eq(flipped.x.domain, (0, 10))
#assert.eq(flipped.y.type, "discrete")
#assert.eq(flipped.y.domain, ("a", "b", "c"))
// Default `auto` policy reverses a discrete post-flip y.
#assert.eq(flipped.y.reverse, true)

// `reverse: false` opts out even when post-flip y is discrete.
#let opt-out = (coord-flip(reverse: false).train)(trained)
#assert.eq(opt-out.y.at("reverse", default: false), false)

// Continuous x flipped to continuous y under default `auto` stays put.
#let cc = (
  x: (type: "continuous", domain: (0, 10)),
  y: (type: "continuous", domain: (0, 1)),
)
#let cc-flipped = (c1.train)(cc)
#assert.eq(cc-flipped.y.at("transform", default: "identity"), "identity")

// Explicit `reverse: true` reverses a continuous post-flip y via a `reverse`
// flag, leaving any numeric transform intact.
#let cc-rev = (coord-flip(reverse: true).train)(cc)
#assert.eq(cc-rev.y.reverse, true)
#assert.eq(cc-rev.y.at("transform", default: "identity"), "identity")

// A log10 x keeps its transform under flip + reverse (regression: the
// reverse used to overwrite the numeric transform with "reverse"). The domain
// is positive because the flip `train` expands it through the log first.
#let cc-log = (
  x: (type: "continuous", domain: (1, 1000), transform: "log10"),
  y: (type: "continuous", domain: (0, 1)),
)
#let cc-log-rev = (coord-flip(reverse: true).train)(cc-log)
#assert.eq(cc-log-rev.y.transform, "log10")
#assert.eq(cc-log-rev.y.reverse, true)

#let untouched = (coord-cartesian().train)(trained)
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

// A geom that draws in the user's x/y space reads its columns from the keys
// the flip swap moved them to, so a flipped range mapping still resolves.
#let flat = (flipped: false)
#let flip = (flipped: true)
#let range-aes = (x: "g", y: "v", ymin: "lo", ymax: "hi")
#assert.eq(user-columns(range-aes, flat), range-aes)
#assert.eq(user-columns(_flip-mapping(range-aes), flip), range-aes)
#assert.eq(
  user-columns((x: "g"), flat),
  (x: "g", y: none, ymin: none, ymax: none),
)

// The user's x axis takes the trained y scale and the vertical canvas range
// under flip.
#let axes-ctx = (
  trained: (x: "tx", y: "ty"),
  px-range: (0, 10),
  py-range: (0, 5),
)
#assert.eq(
  user-axes(axes-ctx + flip),
  (x-trained: "ty", y-trained: "tx", x-range: (0, 5), y-range: (0, 10)),
)
#assert.eq(
  user-axes(axes-ctx),
  (x-trained: "tx", y-trained: "ty", x-range: (0, 10), y-range: (0, 5)),
)
#assert.eq(user-axes(axes-ctx + (trained: (x: "tx"))), none)

#assert.eq(user-point(flat, 1, 2), (1, 2))
#assert.eq(user-point(flip, 1, 2), (2, 1))

// A step along the user's x turns into the other corner order once that
// axis is vertical.
#assert.eq(user-stair-direction("hv", flat), "hv")
#assert.eq(user-stair-direction("hv", flip), "vh")
#assert.eq(user-stair-direction("vh", flip), "hv")
#assert.eq(user-stair-direction(none, flip), none)

coord-flip tests passed.
