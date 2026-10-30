// `compose()` fails when `widths` holds a length, not a weight.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: compose: widths must be

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

#compose(p, p, widths: (1cm, 2cm))
