// `guide-custom()` fails by name when `width` is negative.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-custom: width must be a length of at least

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-custom([x], width: -2cm)
