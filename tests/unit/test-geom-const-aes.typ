// A geom accepts a constant for each aesthetic it reads, captured into
// `layer.params` by `split-aes-params`. Declared params still bind first, and
// a key the geom does not read is rejected with the enum error wording (panics
// cannot be caught in Typst, so the builder is asserted directly; the panic
// itself is covered by tests/errors/geom-constant-unread-key.typ).

#import "../../lib.typ": aes, geom-point, plot
#import "../../src/geom/point.typ": spec as point-spec
#import "../../src/geom/rect.typ": geom-rect
#import "../../src/geom/segment.typ": geom-segment
#import "../../src/geom/label.typ": geom-label
#import "../../src/geom/histogram.typ": geom-histogram
#import "../../src/utils/errors.typ": enum-text

// Aesthetic keys the geom reads but does not declare land in params as
// constants.
#assert.eq(geom-label(nudge-x: 1).params.nudge-x, 1)
#assert.eq(geom-rect(xmin: 2).params.xmin, 2)
#assert.eq(geom-segment(xend: 3).params.xend, 3)

// A constructor built on another draw module takes that module's keys:
// `geom-histogram` builds a `col` layer, which reads `ymin`.
#assert.eq(geom-histogram(ymin: 0).params.ymin, 0)

// A declared parameter binds before `..args`, so the constant path never
// shadows it.
#assert.eq(geom-point(colour: red).params.colour, red)

// `split-aes-params` rejects a key the geom does not read via `fail-enum`, and
// the error lists the geom's own keys.
#let msg = enum-text("geom-point", "argument", "xend", point-spec.reads)
#assert(msg.starts-with("geom-point: argument must be one of "))
#assert(msg.contains("got \"xend\""))
#assert(not msg.contains("\"weight\""))

// Only constants are checked: a plot-level mapping may hold a key that one
// layer's geom does not read.
#let d = ((x: 1, y: 2, w: 0.5), (x: 2, y: 3, w: 0.5))
#plot(
  data: d,
  mapping: aes(x: "x", y: "y", width: "w"),
  layers: (geom-point(),),
)

geom constant-aes param test passed.
