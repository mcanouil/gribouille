// A string `segment-colour` fails under the geom's name.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-text: segment-colour

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-text(segment-colour: "red")
