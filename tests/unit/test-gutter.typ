// `resolve-gutter` normalises a scalar or `(x:, y:)` dict to cm floats.
//
// Rejection contract: a non-length / non-dict value panics with
// "<scope>: gutter must be ...", and a dict with a key outside `x` / `y`
// panics with "<scope>: gutter dictionary keys must be ...". Typst unit tests
// cannot catch panics in-process, so those two paths are verified manually
// whenever the message or accepted shape changes.

#import "../../src/utils/gutter.typ": resolve-gutter

// --- scalar length applies to both axes ---

#let g-scalar = resolve-gutter(0.4cm)
#assert.eq(g-scalar.x, 0.4)
#assert.eq(g-scalar.y, 0.4)

// --- plain number is treated as centimetres ---

#let g-num = resolve-gutter(1)
#assert.eq(g-num.x, 1.0)
#assert.eq(g-num.y, 1.0)

// --- full dict sets each axis independently ---

#let g-dict = resolve-gutter((x: 0.2cm, y: 0.8cm))
#assert.eq(g-dict.x, 0.2)
#assert.eq(g-dict.y, 0.8)

// --- partial dict falls back on the missing axis ---

#let g-part = resolve-gutter((x: 1cm), fallback: 0.5cm)
#assert.eq(g-part.x, 1.0)
#assert.eq(g-part.y, 0.5)

#let g-part-y = resolve-gutter((y: 1.5cm), fallback: 0.3cm)
#assert.eq(g-part-y.x, 0.3)
#assert.eq(g-part-y.y, 1.5)

resolve-gutter tests passed.
