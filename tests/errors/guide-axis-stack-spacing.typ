// `guide-axis-stack()` fails when `spacing` is negative.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-axis-stack: spacing must be a length of at least

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-axis-stack((guide-axis(),), spacing: -10pt)
