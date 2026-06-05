// compose tag-symbol generation: latin, arabic, roman, and spreadsheet wrap.

#import "../../src/compose.typ": (
  _alpha-symbol, _is-compose-spec, _roman-symbol, _tag-symbol, compose, defer,
)
#import "../../src/plot.typ": plot

// Arabic is 1-based.
#assert.eq(_tag-symbol("1", 0), "1")
#assert.eq(_tag-symbol("1", 9), "10")

// Latin upper / lower, with spreadsheet-style wrap past Z.
#assert.eq(_tag-symbol("A", 0), "A")
// Second top-level panel is `B`; a nested compose there descends to `B.<sep>`.
#assert.eq(_tag-symbol("A", 1), "B")
#assert.eq(_tag-symbol("A", 1) + "." + _tag-symbol("1", 0), "B.1")
#assert.eq(_tag-symbol("A", 25), "Z")
#assert.eq(_tag-symbol("A", 26), "AA")
#assert.eq(_tag-symbol("A", 27), "AB")
#assert.eq(_tag-symbol("a", 0), "a")
#assert.eq(_tag-symbol("a", 26), "aa")
#assert.eq(_alpha-symbol(701, true), "ZZ")
#assert.eq(_alpha-symbol(702, true), "AAA")

// Roman is 1-based; lowercase mirrors uppercase.
#assert.eq(_roman-symbol(4), "IV")
#assert.eq(_roman-symbol(2024), "MMXXIV")
#assert.eq(_tag-symbol("I", 0), "I")
#assert.eq(_tag-symbol("I", 8), "IX")
#assert.eq(_tag-symbol("i", 3), "iv")

// `as-spec: true` returns a compose spec usable as a nested panel; panels are
// deferred thunks built with `defer`.
#let fake-panel = defer(
  plot,
  layers: (),
  data: (),
  width: 4cm,
  height: 3cm,
  guides: (:),
  theme: none,
)
#let spec = compose(fake-panel, fake-panel, as-spec: true)
#assert(_is-compose-spec(spec))
#assert.eq(spec.kind, "compose")
#assert.eq(spec.panels.len(), 2)

Compose tag-symbol tests passed.
