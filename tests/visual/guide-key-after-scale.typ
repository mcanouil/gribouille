// A legend key runs the late-binding closures of its layer.
//
// The top plot sets the outline with `after-scale`, the bottom one with
// `stage`. In both, each legend key has the outline that its marker has: the
// fill swatch darkened by 40%.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let d = (
  (x: 1, y: 2, sp: "a"),
  (x: 2, y: 4, sp: "b"),
  (x: 3, y: 3, sp: "c"),
)
#let darken = (c, _) => c.darken(40%)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    fill: "sp",
    colour: after-scale((_, ctx) => {
      let trained = ctx.trained.at("fill")
      ((ctx.resolve-colour)(trained, ctx.palette))(ctx.row.sp).darken(40%)
    }),
  ),
  layers: (geom-point(size: 5pt, stroke: 0.8pt),),
  width: 8cm,
  height: 4cm,
)

#plot(
  data: d,
  mapping: aes(
    x: "x",
    y: "y",
    fill: "sp",
    colour: stage(start: "sp", after-scale: darken),
  ),
  layers: (geom-point(size: 5pt, stroke: 0.8pt),),
  width: 8cm,
  height: 4cm,
)
