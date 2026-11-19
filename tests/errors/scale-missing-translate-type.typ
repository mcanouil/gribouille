// A discrete scale fails when `missing-translate` is not a bool.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: missing-translate

#import "/lib.typ": aes, geom-point, plot, scale-discrete, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  scales: scales(colour: scale-discrete(missing-translate: "no")),
)
