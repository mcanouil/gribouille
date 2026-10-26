// The renderer calls the `panel-size` of a custom coord.
//
// The coord comes from `coord-base` with a `panel-size` that panics, so the
// compile fails only if the renderer calls it. A coord whose `panel-size` the
// renderer skipped would compile. `tools/check-errors.sh` compiles this file,
// requires the compile to fail, and requires the `error:` line to carry the
// phrase below.
//
// expect: custom panel-size ran

#import "/lib.typ": aes, geom-point, plot
#import "/src/coord/contract.typ": coord-base

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1), (x: 2, y: 3)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  coord: coord-base("probe")
    + (panel-size: (t, w, h) => panic("custom panel-size ran")),
  width: 6cm,
  height: 4cm,
)
