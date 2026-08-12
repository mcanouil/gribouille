// Stepped colour scales (scale-steps, scale-steps, viridis-b)
// surface as colourbar candidates with binned: true and bin-boundary breaks.

#import "../../src/render/legend.typ": guides-for

#let layer-point() = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: auto, fill: auto, shape: auto),
)

// Simulate the trained scale that scale-steps(n-breaks: 5) would
// produce: continuous type, domain [0, 25], spec carries binned/n-breaks.
#let trained-stepped = (
  fill: (
    type: "continuous",
    domain: (0, 25),
    spec: (binned: true, n-breaks: 5),
  ),
)

// `guides-for` measures its labels, so each call sits inside a `context`
// block along with the assertions reading its result.
#context {
  let g = guides-for(
    (
      mapping: (fill: "z"),
      layers: (layer-point(),),
      guides: (:),
    ),
    trained-stepped,
  )
  assert.eq(g.len(), 1)
  assert.eq(g.at(0).kind, "colourbar")
  assert.eq(g.at(0).binned, true)
  assert.eq(g.at(0).n-breaks, 5)
  assert.eq(g.at(0).breaks, (0, 5, 10, 15, 20, 25))
}

// Smooth scale: binned defaults to false, breaks fall back to pretty().
#let trained-smooth = (
  fill: (
    type: "continuous",
    domain: (0, 25),
    spec: (binned: false),
  ),
)
#context {
  let g2 = guides-for(
    (mapping: (fill: "z"), layers: (layer-point(),), guides: (:)),
    trained-smooth,
  )
  assert.eq(g2.at(0).binned, false)
}

Guide-coloursteps tests passed.
