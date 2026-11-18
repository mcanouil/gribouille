// A layer with its own `data` that lacks an inherited column reports the layer
// and the missing columns, instead of drawing nothing.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: layer 2 (geom-text)
// expect: flipper-len
// expect: body-mass
// expect: inherit-aes: false

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let notes = ((k: "note", v: 5),)
#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass"),
  layers: (
    geom-point(),
    geom-text(data: notes, mapping: aes(label: "k")),
  ),
)
