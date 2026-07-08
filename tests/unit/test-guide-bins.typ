// Binned non-colour scales (scale-binned, scale-binned, etc.)
// surface as size-ladder candidates with one glyph per bin at the midpoint.

#import "../../src/render/legend.typ": guides-for

#let layer-point() = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (size: auto, alpha: auto),
)

// scale-binned(n-breaks: 4) over domain [1, 10] yields bins of width
// 2.25 with midpoints 2.125, 4.375, 6.625, 8.875.
#let trained-binned-alpha = (
  alpha: (
    type: "continuous",
    domain: (1, 10),
    spec: (binned: true, n-breaks: 4),
  ),
)

#let g = guides-for(
  (
    mapping: (alpha: "w"),
    layers: (layer-point(),),
    guides: (:),
  ),
  trained-binned-alpha,
)

#assert.eq(g.len(), 1)
#assert.eq(g.at(0).kind, "size-ladder")
#assert.eq(g.at(0).binned, true)
#assert.eq(g.at(0).n-breaks, 4)
#assert.eq(g.at(0).breaks.len(), 4)
#assert.eq(g.at(0).breaks, (2.125, 4.375, 6.625, 8.875))

// Smooth scale: pretty() breaks, binned: false.
#let trained-smooth = (
  alpha: (
    type: "continuous",
    domain: (0, 10),
    spec: none,
  ),
)
#let g2 = guides-for(
  (mapping: (alpha: "w"), layers: (layer-point(),), guides: (:)),
  trained-smooth,
)
#assert.eq(g2.at(0).binned, false)
#assert.eq(g2.at(0).n-breaks, 5)

// Explicit `breaks` (bin edges) on a binned ladder place one glyph per bin at
// the interval midpoint, not at the raw edges.
#let trained-edge-alpha = (
  alpha: (
    type: "continuous",
    domain: (0, 10),
    spec: (binned: true, n-breaks: 4, breaks: (0, 2, 6, 10)),
  ),
)
#let g3 = guides-for(
  (mapping: (alpha: "w"), layers: (layer-point(),), guides: (:)),
  trained-edge-alpha,
)
#assert.eq(g3.at(0).kind, "size-ladder")
#assert.eq(g3.at(0).breaks, (1, 4, 8))

Guide-bins tests passed.
