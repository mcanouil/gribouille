// `coord-radial()` rejects a `theta` other than `"x"` or `"y"`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-radial: theta
// expect: "x"

#import "/lib.typ": coord-radial

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-radial(theta: "z")
