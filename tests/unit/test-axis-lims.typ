// guide-axis() and expand-limits() build the expected dictionaries and arrays.

#import "../../src/guide/axis.typ": guide-axis
#import "../../src/guides.typ": guides
#import "../../src/limits.typ": expand-limits
#import "../../src/scale/train.typ": train

#let g = guide-axis(angle: 45)
#assert.eq(g.kind, "guide")
#assert.eq(g.aesthetic, none)
#assert.eq(g.angle, 45)
#assert.eq(g.n-dodge, 1)

#let g2 = guide-axis(angle: 30, n-dodge: 2)
#assert.eq(g2.angle, 30)
#assert.eq(g2.n-dodge, 2)

#let bound = guides(x: guide-axis(angle: 45))
#assert.eq(type(bound), dictionary)
#assert.eq(bound.x.angle, 45)

#let ext = expand-limits(y: 0)
#assert.eq(ext.len(), 1)
#assert.eq(ext.y.aesthetic, "y")
#assert.eq(ext.y.extend, (0,))

#let ext-many = expand-limits(x: (0, 100), y: 10)
#assert.eq(ext-many.x.extend, (0, 100))
#assert.eq(ext-many.y.extend, (10,))

// Train folds extend values into the trained domain.
#let data = (
  (x: 2, y: 3),
  (x: 4, y: 5),
)
#let mapping = (x: "x", y: "y")
#let layers = ((mapping: mapping, data: data, name: "point"),)
#let trained = train(
  scales: expand-limits(y: 0),
  layers: layers,
  mapping: mapping,
  data: data,
)
#assert.eq(trained.y.domain.at(0), 0)
#assert.eq(trained.y.domain.at(1), 5)

Axis-lims tests passed.
