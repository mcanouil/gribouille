// `annotate()` reports an unknown argument under its own scope.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: annotate: argument must be one of

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#annotate("text", x: 1, y: 1, label: "a", foo: 3)
