// `scales()` fails when a viridis scale gets an unknown `option`.
//
// The scale used to fall back to viridis with no message.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-viridis-d: option must be one of

#import "/lib.typ": scale-viridis-d, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-viridis-d(option: "nope"))
