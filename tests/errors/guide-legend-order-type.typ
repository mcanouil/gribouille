// `guide-legend()` fails when `order` is not a whole number.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-legend: order must be a whole number

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-legend(order: "z")
