// `scales()` fails when a ColorBrewer scale gets an unknown palette name.
//
// The message names the constructor the user called, not the internal palette
// lookup.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-brewer: palette must be one of
// expect: got "Nope"

#import "/lib.typ": scale-brewer, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-brewer(palette: "Nope"))
