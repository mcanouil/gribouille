// Paint constants: a colour, a gradient, a tiling and `none` build a layer.

#import "/lib.typ": *

#let layers = (
  geom-point(colour: red),
  geom-point(colour: none),
  geom-col(fill: gradient.linear(red, blue)),
  geom-col(fill: tiling(size: (4pt, 4pt))[#line()]),
  geom-line(stroke: 1.3pt + red),
)

#assert.eq(layers.last().params.colour, red)
