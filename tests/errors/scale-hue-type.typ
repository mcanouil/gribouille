// `scales()` fails when `hue` is not a pair of angles.
//
// A one-element array used to raise the raw Typst error `not enough elements to
// destructure`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-hue: hue must be a (start, end) pair of angles; got (15deg,)

#import "/lib.typ": scale-hue, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-hue(hue: (15deg,)))
