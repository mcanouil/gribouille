// `facet-wrap()` rejects a variable that no layer carries, with layer-only data.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: facet-wrap: variable maps to unknown column "zz"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(data: ((x: 1, y: 1, g: "a"),)),),
  facet: facet-wrap("zz"),
  width: 8cm,
  height: 6cm,
)
