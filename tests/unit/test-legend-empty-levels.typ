// A discrete scale with no levels has nothing to show, so it produces no
// guide at all.
//
// A trained domain is empty when the user pins `limits: ()`, or when every row
// the scale saw was censored by the out-of-range pre-pass. Before this, such a
// scale still reached the renderer and reserved a box holding its title and no
// keys, so a plot lost panel width to a legend that showed nothing.

#import "../../src/render/legend.typ": guides-for

#let layer-point = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: auto, fill: auto, shape: auto),
)

// 1. an empty discrete domain yields no guide.
#context {
  let g = guides-for(
    (mapping: (colour: "g"), layers: (layer-point,), guides: (:)),
    (colour: (type: "discrete", domain: ())),
  )
  assert.eq(g.len(), 0)
}

// 2. the same scale with one level still yields its guide, so the drop is
// bounded to the empty case.
#context {
  let g = guides-for(
    (mapping: (colour: "g"), layers: (layer-point,), guides: (:)),
    (colour: (type: "discrete", domain: ("a",))),
  )
  assert.eq(g.len(), 1)
  assert.eq(g.at(0).levels, ("a",))
}

// 3. an empty discrete scale does not suppress a second aesthetic that has
// levels of its own.
#context {
  let g = guides-for(
    (mapping: (colour: "g", shape: "h"), layers: (layer-point,), guides: (:)),
    (
      colour: (type: "discrete", domain: ()),
      shape: (type: "discrete", domain: ("x", "y")),
    ),
  )
  assert.eq(g.len(), 1)
  assert.eq(g.at(0).aesthetics, ("shape",))
}

empty-level guide tests passed.
