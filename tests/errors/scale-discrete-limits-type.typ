// A discrete scale fails when its `limits` carry a number in place of a level
// name.
//
// The check runs in `_train-entry`, so the plot needs no `strict:` to reach it.
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: a level name as a string
//
// The page is set large enough for the plot to lay out, so this fixture cannot
// fail on a canvas that is too small instead.

#import "/lib.typ": aes, geom-point, plot, scale-discrete, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  scales: scales(colour: scale-discrete(limits: (10, 20))),
)
