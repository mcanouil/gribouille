// `format-number` rejects a negative `digits` in the factory.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: format-number: digits must be `auto` or a non-negative integer

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let f = format-number(digits: -1)
