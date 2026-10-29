// `scales()` fails when `direction` is not a number.
//
// A string used to raise the raw Typst error `cannot compare string and integer`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-distiller: direction must be a number; got "rev"

#import "/lib.typ": scale-distiller, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-distiller(direction: "rev"))
