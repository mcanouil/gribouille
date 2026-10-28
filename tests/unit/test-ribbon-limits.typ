// A ribbon widens the trained y domain to its `ymin` and `ymax`, except on a
// side that the user pins with `limits`. A pinned side stays at the limit,
// and a reversed domain keeps its direction.

#import "../../src/scale/train.typ": train
#import "../../src/render/domain.typ": _post-train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/ribbon.typ": geom-ribbon
#import "../../src/aes.typ": aes
#import "../../src/scales.typ": scales
#import "../../src/scale/constructors.typ": scale-continuous

#let data = (
  (x: 1, y: 4, lo: -5, hi: 20),
  (x: 2, y: 5, lo: 1, hi: 8),
)
#let mapping = aes(x: "x", y: "y", ymin: "lo", ymax: "hi")

#let y-domain(limits) = {
  let layer = geom-ribbon()
  let prepared = (_prepare-layer(layer, mapping, data),)
  let trained = train(
    layers: prepared,
    mapping: mapping,
    data: data,
    scales: if limits == none { scales() } else {
      scales(y: scale-continuous(limits: limits))
    },
  )
  _post-train(trained, prepared).y.domain
}

#for (limits, want) in (
  (none, (-5, 20)),
  ((0, 10), (0, 10)),
  ((auto, 10), (-5, 10)),
  ((0, auto), (0, 20)),
  ((10, 0), (10, 0)),
) {
  let got = y-domain(limits)
  assert.eq(got, want, message: "limits " + repr(limits) + ": " + repr(got))
}
