// With no `missing-value` on a manual alpha scale, the missing mark takes the geom
// default opacity and the legend key leaves alpha out, so the glyph draws at
// its own default of 1. Both are fully opaque.

#import "../../src/utils/colour-resolve.typ": resolve-alpha
#import "../../src/utils/level-resolve.typ": resolve-level
#import "../../src/utils/types.typ": MISSING-KEY

#let trained = (
  type: "discrete",
  domain: ("a", "b", MISSING-KEY),
  missing-level: true,
  spec: (palette: (0.3, 0.9)),
)
#let ctx = (trained: (alpha: trained))

#assert.eq(
  resolve-alpha((:), (alpha: "g"), ctx, (g: none), default-alpha: 1),
  1,
)
#assert.eq(resolve-level("alpha", trained, none), none)
