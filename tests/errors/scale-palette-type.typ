// `scales()` fails when a discrete `palette` is not an array.
//
// A name such as "Set1" used to pass, and the geom then read its first
// letter as a colour.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-discrete: palette must be an array or `auto`; got "Set1"

#import "/lib.typ": scale-discrete, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-discrete(palette: "Set1"))
