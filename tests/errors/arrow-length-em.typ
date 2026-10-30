// `arrow()` fails by name when `length` has an `em` part.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: arrow: length must be an absolute length

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#arrow(length: 1em)
