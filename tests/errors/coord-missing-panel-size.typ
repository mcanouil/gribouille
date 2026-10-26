// `plot()` rejects a coord dictionary that lacks a key of `coord-base`.
//
// The dictionary carries a callable `train` but no `panel-size`, which the
// renderer also calls. `tools/check-errors.sh` compiles this file, requires the
// compile to fail, and requires the `error:` line to carry every phrase below.
//
// expect: plot: coord must carry a callable `train`
// expect: missing `panel-size`

#import "/lib.typ": aes, geom-point, plot

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1),),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  coord: (kind: "coord", name: "cartesian", flipped: false, train: t => t),
  width: 6cm,
  height: 4cm,
)
