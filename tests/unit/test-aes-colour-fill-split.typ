// Verify the colour/fill aesthetic split: `resolve-fill-colour` no longer
// falls back to the colour scale by default, and `geom-point`'s stroke
// builder injects the colour-scale paint only when `stroke` is non-zero.
// Also verifies the precedence rule: pinned `params.colour` wins over the
// trained colour scale.

#import "../../src/utils/fill-resolve.typ": resolve-fill-colour
#import "../../src/utils/colour-resolve.typ": resolve-stroke-colour
#import "../../src/utils/stroke.typ": build-stroke
#import "../../src/utils/aes-pair.typ": aes-set, resolve-pair-defaults

#let fake-trained = (type: "discrete", domain: ("a", "b"))
#let marker-resolve(trained, palette) = value => {
  if trained == none { return rgb("#000000") }
  if value == "a" { rgb("#ff0000") } else { rgb("#0000ff") }
}

#let make-ctx(trained-dict) = (
  trained: trained-dict,
  resolve-colour: marker-resolve,
  palette: (rgb("#111111"), rgb("#222222")),
)

#let layer(fill: auto, alpha: 1) = (
  name: "point",
  params: (fill: fill, alpha: alpha),
)

// 1. Fill mapping with a trained fill scale resolves through the fill scale.
#let ctx-fill = make-ctx((fill: fake-trained))
#let fill-col-row = (k: "a")
#assert.eq(
  resolve-fill-colour(
    layer(),
    (fill: "k"),
    ctx-fill,
    fill-col-row,
    rgb("#cccccc"),
  ),
  rgb("#ff0000"),
)

// 2. Only the colour aesthetic is mapped: with the new default
// `colour-fallback: false`, the fill resolves to `default-fill` and ignores
// the colour scale entirely.
#let ctx-colour = make-ctx((colour: fake-trained))
#assert.eq(
  resolve-fill-colour(
    layer(),
    (colour: "k"),
    ctx-colour,
    (k: "a"),
    rgb("#cccccc"),
  ),
  rgb("#cccccc"),
)

// 3. Opt-in `colour-fallback: true` restores the legacy behaviour for callers
// that genuinely want it (currently none, but the parameter is preserved).
#assert.eq(
  resolve-fill-colour(
    layer(),
    (colour: "k"),
    ctx-colour,
    (k: "b"),
    rgb("#cccccc"),
    colour-fallback: true,
  ),
  rgb("#0000ff"),
)

// 4. A fixed `params.fill` wins over any scale resolution.
#assert.eq(
  resolve-fill-colour(
    layer(fill: rgb("#abcdef")),
    (fill: "k"),
    ctx-fill,
    (k: "a"),
    rgb("#cccccc"),
  ),
  rgb("#abcdef"),
)

// 5. `build-stroke` returns `none` when the layer disables stroke entirely
// or sets it to a zero length, so the `colour` aesthetic has no effect on a
// stroke-less point.
#assert.eq(build-stroke(none, rgb("#ff0000")), none)
#assert.eq(build-stroke(0pt, rgb("#ff0000")), none)

// 6. A length stroke is wrapped into a CeTZ stroke dict with the resolved
// colour-scale paint injected.
#let stroke-from-length = build-stroke(0.5pt, rgb("#ff0000"))
#assert.eq(stroke-from-length.thickness, 0.5pt)
#assert.eq(stroke-from-length.paint, rgb("#ff0000"))

// 7. A user-supplied stroke dict keeps its explicit `paint` and only fills in
// missing fields, so fixed-stroke layers ignore the resolved colour scale.
#let stroke-from-dict = build-stroke(
  (paint: rgb("#222222"), thickness: 0.4pt),
  rgb("#ff0000"),
)
#assert.eq(stroke-from-dict.paint, rgb("#222222"))
#assert.eq(stroke-from-dict.thickness, 0.4pt)

// 8. Mapped colour wins when `params.colour == auto`: `resolve-stroke-colour`
// consults the trained colour scale and returns the colour-scale paint.
#assert.eq(
  resolve-stroke-colour(
    (name: "point", params: (colour: auto, alpha: 1)),
    (colour: "k"),
    ctx-colour,
    (k: "a"),
    rgb("#cccccc"),
  ),
  rgb("#ff0000"),
)

// 9. A fixed `params.colour` overrides the trained colour scale: the pinned
// value wins and the colour-scale paint is ignored.
#assert.eq(
  resolve-stroke-colour(
    (name: "point", params: (colour: rgb("#abcdef"), alpha: 1)),
    (colour: "k"),
    ctx-colour,
    (k: "a"),
    rgb("#cccccc"),
  ),
  rgb("#abcdef"),
)

// 10. `params.colour: none` disables the stroke colour entirely: the mapping
// is ignored and the resolver returns `none`.
#assert.eq(
  resolve-stroke-colour(
    (name: "point", params: (colour: none, alpha: 1)),
    (colour: "k"),
    ctx-colour,
    (k: "a"),
    rgb("#cccccc"),
  ),
  none,
)

// 10b. `params.fill: none` disables the fill: the trained fill scale is
// ignored and the resolver returns `none`.
#assert.eq(
  resolve-fill-colour(
    layer(fill: none),
    (fill: "k"),
    ctx-fill,
    (k: "a"),
    rgb("#cccccc"),
  ),
  none,
)

// 11. Per-row alpha is applied on top of the resolved colour. With alpha 0.5,
// the resulting paint must match the explicitly transparentised colour.
#assert.eq(
  resolve-stroke-colour(
    (name: "point", params: (colour: rgb("#abcdef"), alpha: 0.5)),
    (colour: "k"),
    ctx-colour,
    (k: "a"),
    rgb("#cccccc"),
  ),
  rgb("#abcdef").transparentize(50%),
)

// 12. Suppress-default sentinel: passing `none` as the default makes
// `resolve-fill-colour` return `none` when neither pin nor mapping applies,
// instead of a neutral fallback. This lets dual-aesthetic geoms skip injecting
// a fill default when the user has only set `colour`.
#assert.eq(
  resolve-fill-colour(layer(), (:), make-ctx((:)), (:), none),
  none,
)
#assert.eq(
  resolve-stroke-colour(
    (name: "point", params: (colour: auto, alpha: 1)),
    (:),
    make-ctx((:)),
    (:),
    none,
  ),
  none,
)

// 13. `aes-set` distinguishes pinned, mapped, and unset states. A `none`
// pin counts as unset for the exclusive-default rule, so disabling one
// aesthetic does not strip the other aesthetic's default.
#let make-layer(params) = (name: "x", params: params)
#assert.eq(aes-set(make-layer((colour: auto)), (:), "colour"), false)
#assert.eq(aes-set(make-layer((colour: none)), (:), "colour"), false)
#assert.eq(
  aes-set(make-layer((colour: rgb("#ff0000"))), (:), "colour"),
  true,
)
#assert.eq(
  aes-set(make-layer((colour: auto)), (colour: "k"), "colour"),
  true,
)

// 14. `resolve-pair-defaults` encodes the exclusive rule:
//   - both unset -> both defaults preserved
//   - only colour set -> fill default suppressed
//   - only fill set -> colour default suppressed
//   - both set -> both defaults preserved (caller decides)
#let dc = rgb("#000000")
#let df = rgb("#cccccc")
#assert.eq(
  resolve-pair-defaults(make-layer((colour: auto, fill: auto)), (:), dc, df),
  (dc, df),
)
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: rgb("#ff0000"), fill: auto)),
    (:),
    dc,
    df,
  ),
  (dc, none),
)
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: auto, fill: auto)),
    (colour: "k"),
    dc,
    df,
  ),
  (dc, none),
)
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: auto, fill: rgb("#00ff00"))),
    (:),
    dc,
    df,
  ),
  (none, df),
)
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: auto, fill: auto)),
    (fill: "k"),
    dc,
    df,
  ),
  (none, df),
)
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: rgb("#ff0000"), fill: rgb("#00ff00"))),
    (:),
    dc,
    df,
  ),
  (dc, df),
)

// 14b. A `none` pin must not trigger the exclusive-default rule: disabling
// fill alone should leave the stroke default intact so the geom can still
// render an outline, and vice versa.
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: none, fill: auto)),
    (:),
    dc,
    df,
  ),
  (dc, df),
)
#assert.eq(
  resolve-pair-defaults(
    make-layer((colour: auto, fill: none)),
    (:),
    dc,
    df,
  ),
  (dc, df),
)

// 15. `build-stroke` returns `none` when the resolved paint is `none`, so
// suppressing the colour default propagates through to "no outline drawn".
#assert.eq(build-stroke(0.5pt, none), none)

aesthetic colour/fill split tests passed.
