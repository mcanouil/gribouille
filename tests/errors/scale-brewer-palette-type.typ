// `scales()` fails when a ColorBrewer scale gets a palette that is not a name.
//
// A number used to raise the raw Typst error `expected string, found integer`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-distiller: palette must be a palette name as a string; got 3

#import "/lib.typ": scale-distiller, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-distiller(palette: 3))
