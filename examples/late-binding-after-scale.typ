// `after-scale` transforms an aesthetic's resolved value just before
// the geom draws. Here we mirror the trained fill palette into the
// `colour` (outline) channel and darken it, so each marker's outline
// follows its own fill swatch automatically.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 2, sp: "a"),
  (x: 2, y: 4, sp: "b"),
  (x: 3, y: 3, sp: "c"),
  (x: 4, y: 5, sp: "a"),
  (x: 5, y: 4, sp: "b"),
  (x: 6, y: 6, sp: "c"),
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    fill: "sp",
    colour: after-scale((_, ctx) => {
      let trained = ctx.trained.at("fill", default: none)
      let v = ((ctx.resolve-colour)(trained, ctx.palette))(ctx.row.sp)
      v.darken(40%)
    }),
  ),
  layers: (geom-point(size: 5pt, stroke: 0.8pt),),
  labels: labels(
    title: "Outline Darkened from the Fill Palette via After-Scale",
    fill: "Group",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
