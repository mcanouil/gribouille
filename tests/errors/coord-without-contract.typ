// `plot()` rejects a coord dictionary that carries no callable `train`.
//
// The renderer calls the functions of the coord, so a hand-made dictionary
// tagged `kind: "coord"` has nothing to call. `tools/check-errors.sh` compiles
// this file, requires the compile to fail, and requires the `error:` line to
// carry every phrase below.
//
// expect: plot: coord must carry a callable `train`
// expect: Build it with a `coord-*()` constructor

#import "/lib.typ": aes, geom-point, plot

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1),),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  coord: (kind: "coord", name: "cartesian"),
  width: 6cm,
  height: 4cm,
)
