// A `breaks` closure receives the values the scale trained on and decides the
// tick positions: the helpers here, and any user closure, resolve during
// training so axis ticks, minor gridlines, and guides all read a plain array.

#import "../../lib.typ": (
  aes, breaks-pretty, breaks-quantile, breaks-width, geom-point, geom-rect,
  plot, scale-continuous, scale-gradient, scale-log10, scales,
)
#import "../../src/scale/train.typ": train
#import "../../src/render/axis-format.typ": _axis-breaks, _axis-minor-breaks
#import "../../src/render/prestat.typ": _preprocess-data
#import "../../src/render/legend.typ": guides-for

#let layers = (geom-point(),)
#let d = range(0, 21).map(i => (x: i, y: i * 2))

#let trained-with(scale-set) = train(
  scales: scale-set,
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: d,
)

// --- helpers are pure closures over the value vector ---

#let values = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

#assert.eq((breaks-width(5))(values), (0, 5, 10))
#assert.eq((breaks-width(5, offset: 2))(values), (2, 7))
#assert.eq((breaks-width(2.5))(values), (0, 2.5, 5.0, 7.5, 10.0))

// Whole-number data keeps whole breaks, and `n` is a target, not a promise.
#assert.eq((breaks-pretty(n: 5))(values), (0.0, 2.0, 4.0, 6.0, 8.0, 10.0))
#assert.eq((breaks-pretty(n: 2))(values), (0.0, 5.0, 10.0))

// Quantiles interpolate between neighbouring order statistics.
#assert.eq((breaks-quantile())(values), (0, 2.5, 5, 7.5, 10))
#assert.eq((breaks-quantile(probs: (0, 1)))(values), (0, 10))
#assert.eq((breaks-quantile(probs: (0.5,)))((1, 2, 3, 4)), (2.5,))

// An empty vector (an unmapped scale) yields no breaks rather than failing.
#assert.eq((breaks-width(5))(()), ())
#assert.eq((breaks-pretty())(()), ())
#assert.eq((breaks-quantile())(()), ())

// A range narrower than one step yields no break rather than a spurious one.
#assert.eq((breaks-width(100))((10, 20)), ())

// --- the closure reaches the axis through training ---

#let trained = trained-with(scales(x: scale-continuous(
  breaks: breaks-width(5),
)))
#assert.eq(trained.x.spec.breaks, (0, 5, 10, 15, 20))
#assert.eq(_axis-breaks(trained.x), (0, 5, 10, 15, 20))

// A bare closure works the same as a helper, and sees every trained value.
#let counted = trained-with(
  scales(x: scale-continuous(breaks: v => (v.len(),))),
)
#assert.eq(counted.x.spec.breaks, (21,))

// `minor-breaks` takes a closure too.
#let minor = trained-with(
  scales(
    x: scale-continuous(
      breaks: breaks-width(10),
      minor-breaks: breaks-width(5),
    ),
  ),
)
#assert.eq(minor.x.spec.minor-breaks, (0, 5, 10, 15, 20))
// Positions are kept as written, like an explicit `minor-breaks` array: the
// user placed them, so overlaps with a major are not second-guessed.
#assert.eq(
  _axis-minor-breaks(minor.x, _axis-breaks(minor.x)),
  (0, 5, 10, 15, 20),
)

// A scalar return is accepted and wrapped, matching the explicit-array path.
#let single = trained-with(scales(x: scale-continuous(breaks: v => 7)))
#assert.eq(single.x.spec.breaks, (7,))

// --- the domain is the closure's input, so closure breaks never widen it ---

#let outside = trained-with(scales(x: scale-continuous(breaks: v => (-50, 50))))
#assert.eq(outside.x.domain, (0, 20))
// Out-of-domain positions are clipped away, exactly as for an explicit array.
#assert.eq(_axis-breaks(outside.x), ())

// An explicit array still widens the domain (unchanged behaviour).
#let widened = trained-with(scales(x: scale-continuous(breaks: (-50, 50))))
#assert.eq(widened.x.domain, (-50, 50))

// --- transformed scales hand the closure data-space values ---

// `_preprocess-data` warps the rows into stat space before training, exactly
// as the renderer does, so this is the log10 path a real plot takes: the
// closure must still see 10 .. 10000, not the exponents 1 .. 4.
#let positive = range(1, 5).map(i => (x: calc.pow(10.0, i), y: i))
#let logged-spec = _preprocess-data(plot(
  data: positive,
  mapping: aes(x: "x", y: "y"),
  layers: layers,
  scales: scales(x: scale-log10(breaks: v => (calc.min(..v), calc.max(..v)))),
  as-spec: true,
))
#let logged = train(
  scales: logged-spec.scales,
  layers: logged-spec.layers,
  mapping: logged-spec.mapping,
  data: logged-spec.data,
)
#assert.eq(logged.x.spec.breaks, (10.0, 10000.0))
// The trained domain stays in stat space, so the breaks are the ones the axis
// clips against after `_axis-breaks` unwarps it.
#assert.eq(logged.x.domain, (1.0, 4.0))
#assert.eq(_axis-breaks(logged.x), (10.0, 10000.0))

// --- an axis fed only by xmin/xmax still hands the closure its values ---

#let spans = ((lo: 2, hi: 8, y: 1), (lo: 4, hi: 16, y: 2))
#let fed = train(
  scales: scales(x: scale-continuous(breaks: v => (calc.max(..v),))),
  layers: (geom-rect(),),
  mapping: aes(xmin: "lo", xmax: "hi", ymin: "y", ymax: "y"),
  data: spans,
)
#assert.eq(fed.x.spec.breaks, (16,))

// --- a colour closure reaches the colourbar, not just the axis ---

#let heat = range(0, 11).map(i => (x: i, y: i, z: i * 10))
#let heat-spec = plot(
  data: heat,
  mapping: aes(x: "x", y: "y", colour: "z"),
  layers: layers,
  scales: scales(colour: scale-gradient(breaks: breaks-width(25))),
  as-spec: true,
)
#let heat-trained = train(
  scales: heat-spec.scales,
  layers: heat-spec.layers,
  mapping: heat-spec.mapping,
  data: heat-spec.data,
)
#let bar = guides-for(heat-spec, heat-trained).at(0)
#assert.eq(bar.kind, "colourbar")
#assert.eq(bar.breaks, (0, 25, 50, 75, 100))
