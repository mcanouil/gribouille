// Explicit `breaks` on continuous scales drive axis ticks, replacing the
// auto `pretty()` set, and breaks outside the domain are dropped.

#import "../../src/scale/train.typ": train
#import "../../src/scale/continuous.typ": (
  scale-x-continuous, scale-x-reverse, scale-y-continuous,
)
#import "../../src/scale/date.typ": scale-x-date
#import "../../src/geom/point.typ": geom-point
#import "../../src/aes.typ": aes
#import "../../src/render/axis-format.typ": _axis-breaks
#import "../../src/utils/types.typ": parse-temporal

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

// Without limits, explicit breaks widen the domain so out-of-range breaks
// (0 below the data minimum, 5 above the maximum) become visible.
#let trained-expand = train(
  scales: (scale-x-continuous(breaks: (0, 5)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(trained-expand.x.domain, (0.0, 5.0))
#assert.eq(_axis-breaks(trained-expand.x), (0.0, 5.0))

// A side pinned by an explicit limit is not widened: the low bound stays at 5
// so the break at 0 is dropped, while the unpinned high side expands to 20.
#let trained-pin = train(
  scales: (scale-x-continuous(limits: (5, auto), breaks: (0, 20)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(trained-pin.x.domain, (5.0, 20.0))
#assert.eq(_axis-breaks(trained-pin.x), (20.0,))

// `auto` on one side of `limits` keeps the trained bound for that side.
#let trained-auto-hi = train(
  scales: (scale-x-continuous(limits: (auto, 10)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(trained-auto-hi.x.domain, (1.0, 10.0))
#let trained-auto-lo = train(
  scales: (scale-x-continuous(limits: (0, auto)),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: df,
)
#assert.eq(trained-auto-lo.x.domain, (0.0, 3.0))

// On a log10 scale, user breaks are in data units: decade breaks 1/10/100 sit
// inside the data-space view range (1 to 100) and survive the domain filter.
#let trained-log = (
  type: "continuous",
  domain: (0.0, 2.0),
  transform: "log10",
  pre-transformed: true,
  view-transform: (0.0, 2.0),
  spec: (breaks: (1, 10, 100)),
)
#assert.eq(_axis-breaks(trained-log), (1, 10, 100))

// ISO-8601 date-string breaks on a temporal scale resolve to the same numeric
// days-since-2000 the column data trains against, identical to numeric breaks.
#let date-df = (
  (x: "2024-01-01", y: "1"),
  (x: "2024-06-01", y: "2"),
  (x: "2024-12-01", y: "3"),
)
#let trained-iso = train(
  scales: (scale-x-date(breaks: ("2024-01-01", "2024-06-01", "2024-12-01")),),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: date-df,
)
#assert.eq(
  _axis-breaks(trained-iso.x),
  (
    parse-temporal("2024-01-01", "date"),
    parse-temporal("2024-06-01", "date"),
    parse-temporal("2024-12-01", "date"),
  ),
)
