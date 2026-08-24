// A plot with `strict: true` fails on the first row outside a scale `limits`.
//
// Typst has no try/catch, so a unit test cannot assert this failure and an
// example that panicked would fail `tools/check.sh`. The message is pinned here
// instead: `tools/check-errors.sh` compiles this file, requires the compile to
// fail, and requires the `error:` line to carry every phrase below.
//
// The body and the hint are both pinned, because the hint is the half that
// tells a user what to do about it.
//
// expect: outside limits
// expect: Set `oob: "squish"` to clamp
//
// The page is set large enough for the plot to lay out. A plot that cannot fit
// its canvas raises its own error, and this fixture would then fail for a
// reason that is not the one it names.

#import "/lib.typ": aes, geom-point, plot, scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1), (x: 99, y: 2)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  scales: scales(x: scale-continuous(limits: (0, 10))),
  strict: true,
)
