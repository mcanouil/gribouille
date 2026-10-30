// `guide-axis-stack()` fails when it gets an empty list of guides.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-axis-stack: guides must be a non-empty array

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-axis-stack(())
