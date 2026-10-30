// An element-text margin must be a margin record.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: element-text: margin must be a `margin(...)` record

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#element-text(margin: 5pt)
