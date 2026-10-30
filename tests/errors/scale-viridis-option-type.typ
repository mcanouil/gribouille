// `scales()` fails when a viridis `option` is not a name.
//
// A number used to raise the raw Typst error of the `in` operator.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-viridis-d: option must be a viridis variant name as a string; got 3

#import "/lib.typ": scale-viridis-d, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(colour: scale-viridis-d(option: 3))
