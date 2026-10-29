// `scales()` fails when the grey `start` is outside [0, 1].
//
// The value used to pass to `luma()` unchecked.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-grey: start must be in [0, 1]; got 1.5

#import "/lib.typ": scale-grey, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-grey(start: 1.5))
