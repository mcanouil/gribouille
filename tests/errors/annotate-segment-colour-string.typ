// A string `segment-colour` on `annotate()` fails under its own scope, not the
// scope of the text geom behind it.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: annotate: segment-colour

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#annotate("text", x: 1, y: 1, label: "z", segment-colour: "red")
