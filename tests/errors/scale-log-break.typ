// `scales()` fails when a break on a log10 scale is not positive.
//
// The break used to drop in silence, while a limit at 0 failed.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-log10: breaks must be positive on a log10 scale; got 0

#import "/lib.typ": scale-log10, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-log10(breaks: (0, 10, 100)))
