// Verify guide suppression and key-kind selection when one or more layers
// pin the colour/fill aesthetic locally. A pinned layer must not contribute
// to the aesthetic's guide; if every contributing layer is pinned, the guide
// is suppressed entirely. When two aesthetics map the same column with the
// same trained domain and title, their guides collapse into one merged
// swatch carrying both aesthetics.

#import "../../src/render/legend.typ": guides-for

#let trained = (
  colour: (type: "discrete", domain: ("a", "b")),
  fill: (type: "discrete", domain: ("a", "b")),
)

#let mk-spec(layers) = (
  mapping: (colour: "k", fill: "k"),
  layers: layers,
  guides: (:),
)

#let layer-point(colour: auto, fill: auto) = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: colour, fill: fill),
)

#let layer-line(colour: auto) = (
  name: "line",
  mapping: none,
  inherit-aes: true,
  params: (colour: colour),
)

// 1. Both colour and fill consume column "k" with identical trained domain
// and title; the two candidate guides merge into a single swatch carrying
// both aesthetics. Key kind is `point` (highest geom priority among the
// contributors).
#context {
  let g1 = guides-for(mk-spec((layer-point(),)), trained)
  assert.eq(g1.len(), 1)
  assert.eq(g1.at(0).aesthetics, ("colour", "fill"))
  assert.eq(g1.at(0).key, "point")
}

// 2. Single layer pins `colour`: only the fill candidate is built, so the
// merged group has just one member.
#context {
  let g2 = guides-for(
    mk-spec((layer-point(colour: rgb("#ffffff")),)),
    trained,
  )
  assert.eq(g2.len(), 1)
  assert.eq(g2.at(0).aesthetics, ("fill",))
}

// 3. Mixed pinned/unpinned: pinned point + unpinned line. The colour
// candidate's only contributor is the line layer; the fill candidate's
// only contributor is the point layer (line does not consume fill). The
// merge predicate still holds (same column, domain, title) so the two
// merge into one guide whose key kind is `point` (highest geom priority
// across the union of contributors).
#context {
  let g3 = guides-for(
    mk-spec((layer-point(colour: rgb("#ffffff")), layer-line())),
    trained,
  )
  assert.eq(g3.len(), 1)
  assert.eq(g3.at(0).aesthetics, ("colour", "fill"))
  assert.eq(g3.at(0).key, "point")
}

// 4. Both colour and fill pinned on the only layer: both candidates rejected,
// no guide.
#context {
  let g4 = guides-for(
    mk-spec((layer-point(colour: rgb("#000000"), fill: rgb("#ffffff")),)),
    trained,
  )
  assert.eq(g4.len(), 0)
}

Pinned-layer legend tests passed.
