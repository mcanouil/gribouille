// An unknown direction fails under the name of the guide that got it.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-custom: direction must be one of

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-custom([x], direction: "diagonal")
