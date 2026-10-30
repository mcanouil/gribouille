// theme-set rejects a value that is not a theme.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: theme-set: theme must be a theme dictionary

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-set(5)
