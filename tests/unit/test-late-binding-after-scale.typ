// `after-scale(expr)` runs after the channel's scale resolution and
// transforms the result. The closure receives the resolved value and a
// context dict that includes the row plus the renderer's resolvers.

#import "../../src/utils/late-binding.typ": (
  after-scale, is-late-binding, late-binding-kind,
)
#import "../../src/utils/colour-resolve.typ": (
  resolve-alpha, resolve-linewidth, resolve-size, resolve-stroke-colour,
  resolve-stroke-width,
)
#import "../../src/utils/fill-resolve.typ": resolve-fill-colour
#import "../../src/utils/linetype-resolve.typ": resolve-linetype

// --- constructor + predicates ------------------------------------------

#let m = after-scale((c, _) => c)
#assert.eq(m.kind, "after-scale")
#assert.eq(type(m.expr), function)
#assert(is-late-binding(m))
#assert.eq(late-binding-kind(m), "after-scale")

// --- shared scaffolding ------------------------------------------------

#let fake-trained = (type: "discrete", domain: ("a", "b"))
#let marker-resolve(trained, palette) = value => {
  if value == "a" { rgb("#ff0000") } else { rgb("#0000ff") }
}
#let make-ctx(trained-dict) = (
  trained: trained-dict,
  resolve-colour: marker-resolve,
  palette: (rgb("#111111"),),
  theme: (ink: black),
)
#let layer-of(params) = (name: "point", params: params)

// --- after-scale on `colour` darkens the channel default ---------------

#let darken-half = after-scale((c, _) => c.darken(50%))
#assert.eq(
  resolve-stroke-colour(
    layer-of((colour: auto, alpha: 1)),
    (colour: darken-half),
    make-ctx((:)),
    (:),
    rgb("#888888"),
  ),
  rgb("#888888").darken(50%),
)

// --- closure can read other-channel resolved values via ctx ------------

#let mirror-fill = after-scale((_, ctx) => {
  let trained = ctx.trained.at("fill", default: none)
  ((ctx.resolve-colour)(trained, ctx.palette))(ctx.row.sp)
})
#assert.eq(
  resolve-stroke-colour(
    layer-of((colour: auto, alpha: 1)),
    (colour: mirror-fill, fill: "sp"),
    make-ctx((fill: fake-trained)),
    (sp: "a"),
    rgb("#cccccc"),
  ),
  rgb("#ff0000"),
)

// --- after-scale on `fill` transforms the channel default --------------

#let translucent = after-scale((c, _) => c.transparentize(50%))
#assert.eq(
  resolve-fill-colour(
    layer-of((fill: auto, alpha: 1)),
    (fill: translucent),
    make-ctx((:)),
    (:),
    rgb("#22aa22"),
  ),
  rgb("#22aa22").transparentize(50%),
)

// --- per-row alpha still composes on the after-scale result ------------

#assert.eq(
  resolve-stroke-colour(
    layer-of((colour: auto, alpha: 0.5)),
    (colour: darken-half),
    make-ctx((:)),
    (:),
    rgb("#888888"),
  ),
  rgb("#888888").darken(50%).transparentize(50%),
)

// --- after-scale on `alpha` clamps then transforms ---------------------

#let halve-alpha = after-scale((a, _) => a * 0.5)
#assert.eq(
  resolve-alpha(
    layer-of((alpha: auto)),
    (alpha: halve-alpha),
    make-ctx((:)),
    (:),
    default-alpha: 0.8,
  ),
  0.4,
)

// --- after-scale on `size` doubles the channel default -----------------

#let double-size = after-scale((s, _) => s * 2)
#assert.eq(
  resolve-size(
    layer-of((size: auto)),
    (size: double-size),
    make-ctx((:)),
    (:),
    2pt,
  ),
  4pt,
)

// --- after-scale on `linewidth` doubles the channel default -----------

#assert.eq(
  resolve-linewidth(
    layer-of((linewidth: auto)),
    (linewidth: after-scale((w, _) => w * 2)),
    make-ctx((:)),
    (:),
    0.5pt,
  ),
  1pt,
)

// --- after-scale on `linetype` rewrites the channel default -----------

#assert.eq(
  resolve-linetype(
    layer-of((linetype: auto)),
    (linetype: after-scale((_, _) => "dashed")),
    make-ctx((:)),
    (:),
  ),
  "dashed",
)

// --- after-scale on `stroke` doubles the channel default --------------

#assert.eq(
  resolve-stroke-width(
    layer-of((stroke: auto)),
    (stroke: after-scale((w, _) => w * 2)),
    make-ctx((:)),
    (:),
    0.5pt,
  ),
  1pt,
)

late-binding after-scale tests passed.
