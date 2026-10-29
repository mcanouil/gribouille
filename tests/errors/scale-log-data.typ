// A plot fails when a data cell on a log10 axis is not positive.
//
// The message names the constructor the user called and prints the cell as the
// user wrote it, `0`, not the parsed `0.0`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-log10: x must be positive on a log10 scale; got 0.
//
// The page is set large enough for the plot to lay out, so this fixture cannot
// fail on a canvas that is too small instead.

#import "/lib.typ": aes, geom-point, plot, scale-log10, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 0, y: 1), (x: 10, y: 2)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  scales: scales(x: scale-log10()),
)
