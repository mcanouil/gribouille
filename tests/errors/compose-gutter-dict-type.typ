// `compose()` fails when a gutter dictionary holds a string.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: compose: gutter.x must be a length

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let p = defer(
  plot,
  data: (x: (1, 2), y: (1, 2)),
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(),
  ),
)

#compose(p, p, gutter: (x: "a"))
