// Verify the native Typst `1.3pt + accent` stroke shorthand is desugared into
// the split `stroke` (thickness) / `colour` (paint) pair, on both surfaces that
// take the pair: geom params (via `make-layer`) and theme elements. An explicit
// `colour:` keeps priority over the stroke's embedded paint.

#import "../../src/utils/types.typ": split-stroke-shorthand
#import "../../src/layer.typ": make-layer
#import "../../src/theme/elements.typ": element-line, element-rect

// 1. Shorthand splits thickness and paint; unset colour receives the paint.
#let s1 = split-stroke-shorthand(1.3pt + blue, auto, auto)
#assert.eq(s1.stroke, 1.3pt)
#assert.eq(s1.colour, blue)

// 2. An explicit colour wins over the embedded paint.
#let s2 = split-stroke-shorthand(1.3pt + blue, red, auto)
#assert.eq(s2.stroke, 1.3pt)
#assert.eq(s2.colour, red)

// 3. A paint-only stroke reverts thickness to the caller's sentinel.
#let s3 = split-stroke-shorthand(stroke(paint: blue), auto, auto)
#assert.eq(s3.stroke, auto)
#assert.eq(s3.colour, blue)

// 4. Non-stroke values pass through untouched (colour forwarded as given).
#let s4 = split-stroke-shorthand(1.3pt, red, auto)
#assert.eq(s4.stroke, 1.3pt)
#assert.eq(s4.colour, red)

// 5. Extra stroke fields are preserved as a dictionary alongside the paint.
#let s5 = split-stroke-shorthand(
  stroke(thickness: 1pt, paint: blue, dash: "dashed"),
  auto,
  auto,
)
#assert.eq(
  s5.stroke,
  (thickness: 1pt, dash: (array: (3pt, 3pt), phase: 0pt)),
)
#assert.eq(s5.colour, blue)

// 6. `make-layer` desugars a shorthand geom stroke into split params.
#let p1 = make-layer("point", params: (
  stroke: 1.3pt + blue,
  colour: auto,
)).params
#assert.eq(p1.stroke, 1.3pt)
#assert.eq(p1.colour, blue)

// 7. `make-layer` keeps an explicit colour over the embedded paint.
#let p2 = make-layer("point", params: (
  stroke: 1.3pt + blue,
  colour: red,
)).params
#assert.eq(p2.stroke, 1.3pt)
#assert.eq(p2.colour, red)

// 8. `element-line` accepts the shorthand without panicking on `assert-stroke`.
#let e1 = element-line(stroke: 1pt + red)
#assert.eq(e1.stroke, 1pt)
#assert.eq(e1.colour, red)

// 9. `element-rect` gives an explicit colour priority over the embedded paint.
#let e2 = element-rect(stroke: 1pt + red, colour: blue)
#assert.eq(e2.stroke, 1pt)
#assert.eq(e2.colour, blue)

Stroke shorthand tests passed.
