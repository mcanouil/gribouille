// `scales()` fails when `scale-gradientn()` gets no colour.
//
// The scale used to draw every mark in black ink.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-gradientn: colours must be a non-empty array of colours; got ()

#import "/lib.typ": scale-gradientn, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(fill: scale-gradientn(colours: ()))
