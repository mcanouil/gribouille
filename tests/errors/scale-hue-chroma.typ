// `scales()` fails when `chroma` is outside [0, 100].
//
// The value used to be clamped in silence.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-hue: chroma must be in [0, 100]; got 150

#import "/lib.typ": scale-hue, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-hue(chroma: 150))
