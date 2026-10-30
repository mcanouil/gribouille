// A theme preset checks its ink colour under its own name.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: theme-grey: ink must be a colour; got "red"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-grey(ink: "red")
