// A swatch guide that reverses its levels reverses an array of custom labels
// with them, so each key keeps its own label. A function or `auto` receives
// the level and needs no reordering.

#import "../../lib.typ": (
  aes, geom-point, guide-legend, guides, plot, scale-discrete, scales,
)
#import "../../src/scale/train.typ": train
#import "../../src/render/legend.typ": guides-for

#let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"))

#let three = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))

#let swatch-for(labels, data: d) = {
  let spec = plot(
    data: data,
    mapping: aes(x: "x", y: "y", fill: "g"),
    layers: (geom-point(),),
    scales: scales(fill: scale-discrete(labels: labels)),
    guides: guides(fill: guide-legend(reverse: true)),
    as-spec: true,
  )
  let trained = train(
    scales: spec.scales,
    layers: spec.layers,
    mapping: spec.mapping,
    data: spec.data,
  )
  guides-for(spec, trained).at(0)
}

#context {
  let by-array = swatch-for(("label A", "label B"))
  assert.eq(by-array.levels, ("b", "a"))
  assert.eq(by-array.labels, ("label B", "label A"))

  let upper-case = v => upper(v)
  let by-function = swatch-for(upper-case)
  assert.eq(by-function.levels, ("b", "a"))
  assert.eq(by-function.labels, upper-case)

  let by-default = swatch-for(auto)
  assert.eq(by-default.levels, ("b", "a"))
  assert.eq(by-default.labels, auto)
}

// A labels array shorter than the levels still pairs each level with its own
// entry, and a level without one keeps the level as its label.
#context {
  let short = swatch-for(("A",), data: three)
  assert.eq(short.levels, ("c", "b", "a"))
  assert.eq(short.labels, ("c", "b", "A"))
}
