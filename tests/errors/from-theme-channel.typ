// `from-theme()` rejects a channel that is not a layer parameter.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: from-theme: channel must be one of

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: (x: (1, 2, 3), y: (1, 2, 3), g: ("a", "b", "c")),
  mapping: aes(x: from-theme("ink"), y: "y"),
  layers: (geom-point(),),
)
