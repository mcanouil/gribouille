// Log/sqrt/reverse continuous scale wrappers.
//
// Each wrapper produces a scale spec dict with the same shape as
// `scale-continuous` / `scale-continuous` and the appropriate `trans`
// keyword. Mapping then applies the trans through `map-position`, so a
// mid-domain value lands closer to one endpoint than the linear midpoint.

#import "../../src/scale/continuous.typ": _transform-scale
#import "../../src/scale/train.typ": (
  map-axis, map-position, transform-fwd, transform-inv,
)

// --- spec dicts carry the right aesthetic and trans ---

#let xs-log = _transform-scale("x", "log10")
#assert.eq(xs-log.kind, "scale")
#assert.eq(xs-log.aesthetic, "x")
#assert.eq(xs-log.type, "continuous")
#assert.eq(xs-log.transform, "log10")

#let ys-log = _transform-scale("y", "log10")
#assert.eq(ys-log.aesthetic, "y")
#assert.eq(ys-log.transform, "log10")

#let xs-sqrt = _transform-scale("x", "sqrt")
#assert.eq(xs-sqrt.aesthetic, "x")
#assert.eq(xs-sqrt.transform, "sqrt")

#let ys-sqrt = _transform-scale("y", "sqrt")
#assert.eq(ys-sqrt.aesthetic, "y")
#assert.eq(ys-sqrt.transform, "sqrt")

#let xs-rev = _transform-scale("x", "reverse")
#assert.eq(xs-rev.aesthetic, "x")
#assert.eq(xs-rev.transform, "reverse")

#let ys-rev = _transform-scale("y", "reverse")
#assert.eq(ys-rev.aesthetic, "y")
#assert.eq(ys-rev.transform, "reverse")

// --- map-position honours each trans keyword ---

#let log-trained = (
  type: "continuous",
  domain: (1.0, 100.0),
  spec: xs-log,
  transform: "log10",
)
// log10 of 10 is the midpoint between log10(1) and log10(100), so the value
// 10 sits at the centre of the range.
#assert.eq(map-position(log-trained, 10, (0.0, 10.0)), 5.0)
#assert.eq(map-position(log-trained, 1, (0.0, 10.0)), 0.0)
#assert.eq(map-position(log-trained, 100, (0.0, 10.0)), 10.0)

#let sqrt-trained = (
  type: "continuous",
  domain: (0.0, 100.0),
  spec: xs-sqrt,
  transform: "sqrt",
)
// sqrt(25) is half of sqrt(100), so 25 lands at the midpoint.
#assert.eq(map-position(sqrt-trained, 25, (0.0, 10.0)), 5.0)
#assert.eq(map-position(sqrt-trained, 0, (0.0, 10.0)), 0.0)
#assert.eq(map-position(sqrt-trained, 100, (0.0, 10.0)), 10.0)

#let rev-trained = (
  type: "continuous",
  domain: (0.0, 10.0),
  spec: xs-rev,
  transform: "reverse",
)
// Reversed: domain low maps to range high.
#assert.eq(map-position(rev-trained, 0, (0.0, 10.0)), 10.0)
#assert.eq(map-position(rev-trained, 10, (0.0, 10.0)), 0.0)
#assert.eq(map-position(rev-trained, 5, (0.0, 10.0)), 5.0)

// --- map-axis (numeric fast path used by the renderer) matches map-position ---

#assert.eq(
  map-axis(log-trained, 10, (0.0, 10.0)),
  map-position(log-trained, 10, (0.0, 10.0)),
)
#assert.eq(
  map-axis(rev-trained, 3, (0.0, 10.0)),
  map-position(rev-trained, 3, (0.0, 10.0)),
)

// --- sqrt inverse round-trips and clamps below-zero padded bounds ---

#assert.eq(transform-fwd("sqrt", 9.0), 3.0)
#assert.eq(transform-inv("sqrt", 3.0), 9.0)
#assert.eq(transform-inv("sqrt", 0.0), 0.0)
// A padded view bound below zero floors at 0 instead of reflecting positive.
#assert.eq(transform-inv("sqrt", -0.5), 0.0)

Scale trans tests passed.
