// A plot names the aesthetic of a feeder column when its cell is not positive
// on a log10 axis.
//
// The cell is in the `xmin` column, so the message names `xmin`, not the axis
// `x`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-log10: xmin must be positive on a log10 scale; got 0.
//
// The page is set large enough for the plot to lay out, so this fixture cannot
// fail on a canvas that is too small instead.

#import "/lib.typ": aes, geom-errorbarh, plot, scale-log10, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((y: 1, lo: 0, hi: 10), (y: 2, lo: 1, hi: 100)),
  mapping: aes(y: "y", xmin: "lo", xmax: "hi"),
  layers: (geom-errorbarh(),),
  scales: scales(x: scale-log10()),
)
