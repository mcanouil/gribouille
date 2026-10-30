// `guides()` fails when a value is a dictionary that is not a guide.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guides: value for

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guides(colour: (a: 1))
