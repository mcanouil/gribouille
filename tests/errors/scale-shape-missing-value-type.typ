// A shape scale fails when `missing-value` is a number instead of a shape keyword.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: missing-value

#import "/lib.typ": aes, geom-point, plot, scale-manual, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b")),
  mapping: aes(x: "x", y: "y", shape: "g"),
  layers: (geom-point(),),
  scales: scales(shape: scale-manual(
    values: ("circle", "square"),
    missing-value: 3,
  )),
)
