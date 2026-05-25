// Explicit `breaks` on continuous scales drive axis ticks, replacing the
// auto `pretty()` set, and breaks outside the domain are dropped.

#import "../../src/scale/train.typ": train
#import "../../src/scale/continuous.typ": (
  scale-x-continuous, scale-x-reverse, scale-y-continuous,
)
#import "../../src/geom/point.typ": geom-point
#import "../../src/aes.typ": aes
#import "../../src/render.typ": _axis-breaks

#let df = (
  (x: "1", y: "10"),
  (x: "2", y: "20"),
  (x: "3", y: "30"),
)
#let layers = (geom-point(),)

// User breaks fully inside the limits are returned verbatim, in order.
#let trained = train(
  scales: (scale-x-continuous(limits: (0, 10), breaks: (0, 5, 10)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(_axis-breaks(trained.x), (0.0, 5.0, 10.0))

// Breaks outside the domain are dropped; only in-range values survive.
#let trained-oob = train(
  scales: (scale-x-continuous(limits: (0, 10), breaks: (0, 5, 99)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(_axis-breaks(trained-oob.x), (0.0, 5.0))

// Without explicit breaks, the auto `pretty()` set still applies (unchanged).
#let trained-auto = train(
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert(_axis-breaks(trained-auto.y).len() > 0)

// A single in-range break on y is honoured on its own.
#let trained-y = train(
  scales: (scale-y-continuous(limits: (0, 30), breaks: (15,)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(_axis-breaks(trained-y.y), (15.0,))

// A reversed scale with descending `limits` stores its domain as `(hi, lo)`;
// in-range breaks must still survive the domain filter.
#let trained-rev = train(
  scales: (scale-x-reverse(limits: (2024, 2010), breaks: (2012, 2016, 2020)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(_axis-breaks(trained-rev.x), (2012.0, 2016.0, 2020.0))

// A scalar `breaks` is coerced to a one-element array, not panicked on.
#let trained-scalar = train(
  scales: (scale-x-continuous(limits: (0, 10), breaks: 5),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(_axis-breaks(trained-scalar.x), (5.0,))
