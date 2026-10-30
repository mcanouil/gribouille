// theme checks its ink colour.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: theme: ink must be a colour

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme(ink: "red")
