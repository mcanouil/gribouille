// `scales()` fails when a log10 limit is not positive.
//
// The message prints `0` as the user wrote it, not the parsed `0.0`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-log10: lower limit must be positive on a log10 scale; got 0.

#import "/lib.typ": scale-log10, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(y: scale-log10(limits: (0, 10)))
