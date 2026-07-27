// `dup-axis`/`sec-axis` state their breaks in primary units. Their own array
// wins over the primary grid, clipped to the visible domain, and a closure
// resolves during training exactly like a primary `breaks` closure.

#import "../../lib.typ": (
  aes, breaks-width, dup-axis, geom-point, scale-continuous, scales, sec-axis,
)
#import "../../src/scale/train.typ": train
#import "../../src/render/axis-format.typ": (
  _axis-breaks, _sec-spec, _secondary-breaks, _shared-axis-breaks,
)
#import "../../src/render/domain.typ": _apply-expand

#let layers = (geom-point(),)
#let d = range(0, 21).map(i => (x: i, y: i * 2))

#let trained-with(scale-set) = _apply-expand(
  train(
    scales: scale-set,
    layers: layers,
    mapping: aes(x: "x", y: "y"),
    data: d,
  ),
  none,
)

// --- an explicit secondary array wins over the primary grid ---

#let pinned = trained-with(
  scales(x: scale-continuous(secondary: dup-axis(breaks: (0, 10, 20)))),
)
#assert.eq(_secondary-breaks(pinned.x, _sec-spec(pinned.x), (1, 2, 3)), (
  0,
  10,
  20,
))
#assert.eq(_shared-axis-breaks(pinned).x-sec, (0, 10, 20))
// The primary axis keeps its own automatic breaks.
#assert.eq(_shared-axis-breaks(pinned).x, _axis-breaks(pinned.x))

// Positions outside the visible domain are dropped rather than drawn off panel.
#let overshoot = trained-with(
  scales(x: scale-continuous(secondary: dup-axis(breaks: (-5, 10, 99)))),
)
#assert.eq(_shared-axis-breaks(overshoot).x-sec, (10,))

// --- `auto` still mirrors the primary axis ---

#let mirrored = trained-with(
  scales(x: scale-continuous(secondary: dup-axis(name: "top"))),
)
#assert.eq(_shared-axis-breaks(mirrored).x-sec, _axis-breaks(mirrored.x))

// A scale with no secondary axis reports no secondary breaks.
#let plain = trained-with(scales(x: scale-continuous()))
#assert.eq(_shared-axis-breaks(plain).x-sec, none)

// --- a closure resolves during training, in primary units ---

#let closured = trained-with(
  scales(
    y: scale-continuous(
      secondary: sec-axis(transform: v => v / 2, breaks: breaks-width(20)),
    ),
  ),
)
#assert.eq(closured.y.spec.secondary.breaks, (0, 20, 40))
#assert.eq(_shared-axis-breaks(closured).y-sec, (0, 20, 40))
