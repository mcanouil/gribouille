// An element-text colour must be a colour, not a string.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: element-text: colour must be a colour

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#element-text(colour: "red")
