// `sec-axis()` fails when `transform` is neither a function nor "identity".
//
// A name such as "log10" used to raise the raw Typst error `expected function,
// found string` at render time.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: sec-axis: transform must be a function or "identity"; got "log10"

#import "/lib.typ": sec-axis

#set page(width: 10cm, height: 8cm, margin: 0pt)

#sec-axis(transform: "log10")
