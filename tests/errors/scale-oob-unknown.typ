// `scales()` fails when a colour scale gets an unknown `oob` mode.
//
// Only the position scales used to check `oob`. Every other scale accepted a
// typo and acted as if it read "drop".
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-viridis-c: oob must be one of "drop", "squish"; got "squash"

#import "/lib.typ": scale-viridis-c, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-viridis-c(oob: "squash"))
