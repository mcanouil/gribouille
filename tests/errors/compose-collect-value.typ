// `compose()` fails when `collect` is a string other than `"all"`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: compose: collect must be `auto`, `none`, `"all"`, or an array of aesthetic names; got "some"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let d = (x: (1, 2), y: (1, 2))
#let p = defer(plot, data: d, mapping: aes(x: "x", y: "y"), layers: (
  geom-point(),
))

#compose(p, p, collect: "some")
