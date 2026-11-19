// A linetype scale fails when `na-value` is not a Typst dash keyword.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: na-value

#import "/lib.typ": aes, geom-line, plot, scale-discrete, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b")),
  mapping: aes(x: "x", y: "y", linetype: "g"),
  layers: (geom-line(),),
  scales: scales(linetype: scale-discrete(na-value: "zig-zag")),
)
