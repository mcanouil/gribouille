// A negative tick length fails at the builder.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: element-tick: length must be a length or ratio of at least 0; got -3pt

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#element-tick(length: -3pt)
