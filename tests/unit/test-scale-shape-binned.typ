// scale-binned: continuous-binned shape scale.

#import "../../src/scale/shape.typ": _shape-binned
#import "../../src/utils/level-resolve.typ": bin-index, resolve-level
#import "../../src/utils/palette.typ": default-shapes

#let s = _shape-binned()
#assert.eq(s.kind, "scale")
#assert.eq(s.aesthetic, "shape")
#assert.eq(s.type, "continuous")
#assert.eq(s.binned, true)
#assert.eq(s.n-breaks, 4)
#assert.eq(s.palette, default-shapes)

#let s2 = _shape-binned(n-breaks: 6, palette: (
  "circle",
  "square",
  "triangle",
  "diamond",
  "cross",
  "x",
))
#assert.eq(s2.n-breaks, 6)
#assert.eq(s2.palette.len(), 6)

// bin-index helper.
#assert.eq(bin-index(0, 0, 10, 4), 0)
#assert.eq(bin-index(2, 0, 10, 4), 0)
#assert.eq(bin-index(2.5, 0, 10, 4), 1)
#assert.eq(bin-index(7.5, 0, 10, 4), 3)
#assert.eq(bin-index(10, 0, 10, 4), 3)
#assert.eq(bin-index(-1, 0, 10, 4), 0)
#assert.eq(bin-index(99, 0, 10, 4), 3)
#assert.eq(bin-index(5, 0, 0, 4), 0)

// resolve-level snaps continuous values to bin shapes.
#let trained = (
  type: "continuous",
  domain: (0, 12),
  spec: (binned: true, n-breaks: 4, palette: default-shapes),
)
#let r0 = resolve-level("shape", trained, 0)
#let r-mid = resolve-level("shape", trained, 6)
#let r-end = resolve-level("shape", trained, 12)
#assert.eq(r0, default-shapes.at(0))
#assert.eq(r-mid, default-shapes.at(2))
#assert.eq(r-end, default-shapes.at(3))

// Smooth (non-binned) continuous shape stays unresolved.
#let smooth = (
  type: "continuous",
  domain: (0, 12),
  spec: none,
)
#assert.eq(resolve-level("shape", smooth, 5), none)

scale-binned tests passed.
