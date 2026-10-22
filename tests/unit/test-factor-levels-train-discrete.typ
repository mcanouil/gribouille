// A layer that records `_factor-levels` for a column trains that column as a
// discrete scale, even when its mapping is a plain column name. The free-scale
// retrain of a facet panel reads layers whose mapping refs are already
// stripped, so the recorded levels alone must keep the axis discrete under a
// numeric-offset position (beeswarm, jitter, nudge).

#import "../../src/scale/train.typ": positional-aesthetics, train

#let pos-col = "_gribouille-pos-g"
#let layer = (
  mapping: (kind: "aes", x: pos-col, y: "v"),
  data: (
    (g: "b", v: 1, (pos-col): 0.9),
    (g: "c", v: 2, (pos-col): 2.1),
  ),
  inherit-aes: false,
  _factor-levels: ((pos-col): ("b", "c")),
)

#let trained = train(
  scales: (:),
  layers: (layer,),
  mapping: none,
  data: none,
  aesthetics: positional-aesthetics,
)
#assert.eq(trained.x.type, "discrete")
#assert.eq(trained.x.domain, ("b", "c"))
#assert.eq(trained.y.type, "continuous")
