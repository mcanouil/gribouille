// A discrete scale with no levels has nothing to show, so it produces no
// guide at all.
//
// A trained domain is empty when the user pins `limits: ()`, or when the
// mapped column holds nothing but `none` and empty strings, which the level
// collector skips. Before this, such a scale still reached the renderer and
// reserved a box holding its title and no keys, so a plot lost panel width to
// a legend that showed nothing.

#import "../../src/render/legend.typ": guides-for
#import "../../src/scale/train.typ": train
#import "../../src/aes.typ": aes

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

// 4. the second cause, end to end: a column holding nothing but `none` trains
// a discrete scale to an empty domain, which then yields no guide.
#context {
  let data = ((x: 1, g: none), (x: 2, g: none))
  let mapping = aes(x: "x", colour: "g")
  let trained = train(
    layers: ((mapping: mapping, data: data, name: "point"),),
    mapping: mapping,
    data: data,
    aesthetics: ("x", "y", "colour"),
  )
  assert.eq(trained.colour.type, "discrete")
  assert.eq(trained.colour.domain, ())
  let g = guides-for(
    (mapping: mapping, layers: (layer-point,), guides: (:)),
    (colour: trained.colour),
  )
  assert.eq(g.len(), 0)
}

empty-level guide tests passed.
