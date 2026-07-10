// Tiling paints flow through the fill pipeline without alpha or seam crashes.

#import "../../src/utils/colour-resolve.typ": apply-alpha, is-opaque
#import "../../src/utils/stroke.typ": seal-seam
#import "/lib.typ": *

#let stripes = tiling(size: (4pt, 4pt))[
  #place(line(start: (0%, 100%), end: (100%, 0%), stroke: 0.7pt + black))
]

// --- paint-pipeline guards ---------------------------------------------------

// A tiling has no alpha channel: apply-alpha passes it through untouched at
// any alpha instead of panicking in `transparentize`. (Tiling values do not
// compare equal in Typst, so assert on the returned type.)
#assert.eq(type(apply-alpha(stripes, 0.5)), tiling)
#assert.eq(type(apply-alpha(stripes, 1)), tiling)
#assert.eq(type(apply-alpha(stripes, none)), tiling)

// Colours keep their behaviour.
#assert.eq(apply-alpha(rgb("#336699"), 1), rgb("#336699"))
#assert.eq(apply-alpha(rgb("#336699"), 0.5), rgb("#336699").transparentize(50%))
#assert.eq(apply-alpha(none, 0.5), none)

// Seam sealing treats non-colour paints as not-opaque and skips the
// self-stroke instead of panicking in `components`.
#assert(not is-opaque(stripes))
#assert(is-opaque(rgb("#336699")))
#assert.eq(seal-seam(none, stripes), none)

// --- end-to-end: tilings as mapped and fixed fills ----------------------------
// Compiling these plots exercises the manual palette, the fill resolution
// chain, the legend swatches, and the polygon/rect draw paths with a
// non-colour paint.

#let d = (
  (g: "a", k: "u", n: 3),
  (g: "a", k: "v", n: 2),
  (g: "b", k: "u", n: 4),
  (g: "b", k: "v", n: 3),
)
#plot(
  data: d,
  mapping: aes(x: "g", y: "n", fill: "k"),
  layers: (geom-col(position: "dodge"),),
  scales: scales(fill: scale-manual(values: (stripes, rgb("#336699")))),
  width: 8cm,
  height: 5cm,
)

#let dl = range(0, 8).map(i => (x: i, y: calc.sin(i * 0.6) + 1.5))
#plot(
  data: dl,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-area(fill: stripes),),
  width: 8cm,
  height: 4cm,
)

tiling-fills tests passed.
