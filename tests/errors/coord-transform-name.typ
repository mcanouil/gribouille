// `coord-transform()` rejects a transform name that `scale-continuous` does not know.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-transform: x must be one of
// expect: "log10"
// expect: got "log"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-transform(x: "log")
