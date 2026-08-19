// `breaks-log` places ticks on powers of a base, and fills in sub-decade steps
// when too few powers fall inside the data range. The counts below follow
// `scales::breaks_log()`, so a log axis ticks the way ggplot2 ticks it.

#import "../../lib.typ": (
  aes, breaks-log, geom-point, plot, scale-continuous, scale-log10, scales,
)
#import "../../src/scale/train.typ": train
#import "../../src/render/axis-format.typ": _axis-breaks
#import "../../src/render/prestat.typ": _preprocess-data

// `calc.pow` returns floats, so break positions are compared with a relative
// whisker rather than for equality.
#let close(got, want) = {
  if got.len() != want.len() { return false }
  for (i, w) in want.enumerate() {
    let g = got.at(i)
    if calc.abs(g - w) > 1e-6 * calc.max(1.0, calc.abs(w)) { return false }
  }
  true
}

#let layers = (geom-point(),)

// --- powers of ten cover the range ---

#assert(close((breaks-log())((1, 10000)), (1, 10, 100, 1000, 10000)))
#assert(close((breaks-log())((1, 100)), (1, 10, 100)))
#assert(close((breaks-log())((0.001, 1)), (0.001, 0.01, 0.1, 1)))

// A wide span thins the powers, here to every second decade.
#assert(close(
  (breaks-log())((1, 1000000000)),
  (1, 100, 10000, 1000000, 100000000),
))

// A range inside one decade has a single power to offer.
#assert(close((breaks-log())((100, 100)), (100,)))

// --- sub-decade fill-in ---

// Ten to a hundred holds one power, so mantissas fill in until three breaks
// land in range. The result carries one break of padding either side, which
// `_axis-breaks` clips off against the visible domain.
#assert(close((breaks-log())((80, 120)), (70, 80, 90, 100, 200)))

// A range too narrow for any mantissa set falls back to the linear search.
#let narrow = (breaks-log())((95, 105))
#assert(narrow.len() > 0)
#for i in range(1, narrow.len()) {
  assert(narrow.at(i) > narrow.at(i - 1), message: "breaks must ascend")
}

// --- other bases ---

#assert(close((breaks-log(base: 2))((1, 8)), (1, 2, 4, 8)))
#assert(close((breaks-log(base: 2))((1, 1024)), (1, 8, 64, 512)))

// --- degenerate input ---

// An empty vector (an unmapped scale) yields no breaks rather than failing.
#assert.eq((breaks-log())(()), ())

// Non-positive values drop out, as they do on a log axis.
#assert(close((breaks-log())((0, -5, 1000)), (1000,)))

// --- the closure reaches the axis through training ---

// `_preprocess-data` warps the rows into stat space before training, exactly as
// the renderer does, so the closure must see 10 .. 10000, not the exponents.
#let decades = range(1, 5).map(i => (x: calc.pow(10.0, i), y: i))
#let logged-spec = _preprocess-data(plot(
  data: decades,
  mapping: aes(x: "x", y: "y"),
  layers: layers,
  scales: scales(x: scale-log10(breaks: breaks-log())),
  as-spec: true,
))
#let logged = train(
  scales: logged-spec.scales,
  layers: logged-spec.layers,
  mapping: logged-spec.mapping,
  data: logged-spec.data,
)
#assert(close(logged.x.spec.breaks, (10, 100, 1000, 10000)))
// The trained domain stays in stat space.
#assert.eq(logged.x.domain, (1.0, 4.0))
#assert(close(_axis-breaks(logged.x), (10, 100, 1000, 10000)))

// A linear axis takes log breaks too; they simply bunch towards the low end.
#let linear = train(
  scales: scales(x: scale-continuous(breaks: breaks-log())),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: decades,
)
#assert(close(linear.x.spec.breaks, (10, 100, 1000, 10000)))

// Closure breaks never widen the domain, so the padding of a narrow range
// leaves the trained domain alone.
#let padded = train(
  scales: scales(x: scale-continuous(breaks: breaks-log())),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: ((x: 80, y: 1), (x: 120, y: 2)),
)
#assert.eq(padded.x.domain, (80, 120))
