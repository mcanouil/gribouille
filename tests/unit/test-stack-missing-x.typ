// A stack leaves a row with a missing x alone on a continuous x, so the y
// domain is the one of the same data without that row. On a discrete x the
// missing x is the NA level and stacks as a bucket of its own.

#import "../../src/position/apply.typ": apply-position

#let mapping = (x: "x", y: "y")
#let ymaxs(rows) = rows.map(r => r.at("ymax", default: none))

#let continuous = ((x: 1, y: 2), (x: 1, y: 3), (x: 2, y: 4))
#let with-missing = continuous + ((x: none, y: 10), (x: "", y: 10))
#let plain = apply-position("stack", continuous, mapping)
#let skipped = apply-position("stack", with-missing, mapping)
#assert.eq(ymaxs(skipped.data).slice(0, 3), ymaxs(plain.data))
#assert.eq(ymaxs(skipped.data).slice(3), (none, none))

#let discrete = (
  (x: "a", y: 2),
  (x: none, y: 3),
  (x: "a", y: 1),
  (x: none, y: 4),
)
#assert.eq(ymaxs(apply-position("stack", discrete, mapping).data), (
  3.0,
  7.0,
  1.0,
  4.0,
))
