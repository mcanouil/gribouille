// A discrete scale fails when its `limits` carry `none`: a missing value is
// not a level, and the hint points to `na-translate`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: limits
// expect: na-translate

#import "/lib.typ": aes, geom-point, plot, scale-discrete, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  scales: scales(colour: scale-discrete(limits: ("a", none))),
)
