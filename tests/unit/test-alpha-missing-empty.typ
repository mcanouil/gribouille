// An empty-string cell resolves like `none` on an alpha scale, with and
// without a missing level.

#import "../../src/utils/colour-resolve.typ": resolve-alpha
#import "../../src/utils/types.typ": MISSING-KEY

#let ctx(missing-level) = (
  trained: (
    alpha: (
      type: "discrete",
      domain: if missing-level { ("a", "b", MISSING-KEY) } else { ("a", "b") },
      missing-level: missing-level,
      spec: (palette: (0.3, 0.9), missing-value: 0.5),
    ),
  ),
)
#let mapping = (alpha: "g")

#for missing-level in (true, false) {
  assert.eq(
    resolve-alpha(
      (:),
      mapping,
      ctx(missing-level),
      (g: ""),
      default-alpha: 0.7,
    ),
    resolve-alpha(
      (:),
      mapping,
      ctx(missing-level),
      (g: none),
      default-alpha: 0.7,
    ),
  )
}
#assert.eq(
  resolve-alpha((:), mapping, ctx(true), (g: ""), default-alpha: 0.7),
  0.5,
)
#assert.eq(
  resolve-alpha((:), mapping, ctx(false), (g: ""), default-alpha: 0.7),
  0.7,
)
