// Any aesthetic key may be pinned as a constant directly on a geom, captured
// into `layer.params` by `split-aes-params`. Declared params still bind
// first, and an unknown key is rejected with the enum error wording (panics
// cannot be caught in Typst, so the builder is asserted directly).

#import "../../src/aes-keys.typ": AES-KEYS
#import "../../src/geom/point.typ": geom-point
#import "../../src/geom/rect.typ": geom-rect
#import "../../src/geom/segment.typ": geom-segment
#import "../../src/geom/label.typ": geom-label
#import "../../src/utils/errors.typ": enum-text

// Aesthetic keys the geom does not declare land in params as constants.
#assert.eq(geom-point(nudge-x: 1).params.nudge-x, 1)
#assert.eq(geom-rect(nudge-y: 2).params.nudge-y, 2)
#assert.eq(geom-segment(group: "g").params.group, "g")
#assert.eq(geom-label(weight: 3).params.weight, 3)

// A declared parameter binds before `..args`, so the constant path never
// shadows it.
#assert.eq(geom-point(colour: red).params.colour, red)

// `split-aes-params` rejects an unknown key via `fail-enum`; assert the
// wording its builder produces for a typo'd aesthetic.
#let msg = enum-text("geom-point", "argument", "colur", AES-KEYS)
#assert(msg.starts-with("geom-point: argument must be one of "))
#assert(msg.contains("got \"colur\""))

geom constant-aes param test passed.
