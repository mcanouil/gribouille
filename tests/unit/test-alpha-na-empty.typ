// An empty-string cell resolves like `none` on an alpha scale, with and
// without an NA level.

#import "../../src/utils/colour-resolve.typ": resolve-alpha
#import "../../src/utils/types.typ": NA-KEY

#let ctx(na-level) = (
  trained: (
    alpha: (
      type: "discrete",
      domain: if na-level { ("a", "b", NA-KEY) } else { ("a", "b") },
      na-level: na-level,
      spec: (palette: (0.3, 0.9), na-value: 0.5),
    ),
  ),
)
#let mapping = (alpha: "g")

#for na-level in (true, false) {
  assert.eq(
    resolve-alpha((:), mapping, ctx(na-level), (g: ""), default-alpha: 0.7),
    resolve-alpha((:), mapping, ctx(na-level), (g: none), default-alpha: 0.7),
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
