// The NA level reads `NA` in guides, on axes and in facet strips, and a user
// `labels` array or function can relabel it. Grouping keys a missing cell as
// its own bucket, and the oob pre-pass drops it only under `na-translate:
// false`.

#import "../../src/utils/aes-resolve.typ": level-text, resolve-label
#import "../../src/utils/types.typ": NA-KEY
#import "../../src/utils/group.typ": bucket-by-col
#import "../../src/render/legend.typ": _swatch-label, guides-for
#import "../../src/render/axis-format.typ": _tick-label-fallback
#import "../../src/render/prestat.typ": _raw-levels-for
#import "../../src/scale/train.typ": train
#import "../../src/scale/constructors.typ": scale-discrete
#import "../../src/scale/oob.typ": filter-oob, oob-plans
#import "../../src/scales.typ": scales
#import "../../src/aes.typ": aes

#assert.eq(level-text(NA-KEY), "NA")
#assert.eq(level-text("f"), "f")
#assert.eq(_tick-label-fallback((type: "discrete"), NA-KEY), "NA")

// A function of the level gets `none` for the NA level.
#assert.eq(
  resolve-label(l => if l == none { "missing" } else { l }, NA-KEY, 2, "NA"),
  "missing",
)
#assert.eq(resolve-label(("F", "M", "?"), NA-KEY, 2, "NA"), "?")
#assert.eq(resolve-label(("F", "M"), NA-KEY, 2, "NA"), "NA")

#let layer-point = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: auto, fill: auto, shape: auto),
)
#let na-scale = (type: "discrete", domain: ("f", "m", NA-KEY), na-level: true)
#let swatch(labels: auto, reverse: false) = {
  let scale = (..na-scale, spec: (labels: labels))
  guides-for(
    (
      mapping: (colour: "g", fill: "g"),
      layers: (layer-point,),
      guides: if reverse {
        (colour: (reverse: true), fill: (reverse: true))
      } else { (:) },
    ),
    (colour: scale, fill: scale),
  )
}
#let texts(g) = range(g.levels.len()).map(i => _swatch-label(g, i))

#context {
  // Colour and fill on one column with NA still merge into one guide.
  let g = swatch()
  assert.eq(g.len(), 1)
  assert.eq(g.at(0).aesthetics, ("colour", "fill"))
  assert.eq(g.at(0).levels, ("f", "m", NA-KEY))
  assert.eq(texts(g.at(0)), ("f", "m", "NA"))

  let g = swatch(labels: ("F", "M", "Unknown")).at(0)
  assert.eq(texts(g), ("F", "M", "Unknown"))

  let g = swatch(labels: l => if l == none { "?" } else { upper(l) }).at(0)
  assert.eq(texts(g), ("F", "M", "?"))

  // `reverse: true` keeps each label with its level, NA included.
  let g = swatch(labels: ("F", "M", "Unknown"), reverse: true).at(0)
  assert.eq(g.levels, (NA-KEY, "m", "f"))
  assert.eq(texts(g), ("Unknown", "M", "F"))
  let g = swatch(labels: ("F",), reverse: true).at(0)
  assert.eq(texts(g), ("NA", "m", "F"))
}

// A missing x forms its own bucket and does not fail.
#let rows = ((x: "a", y: 1), (x: none, y: 2), (x: "a", y: 3), (x: "", y: 4))
#assert.eq(bucket-by-col(rows, "x").len(), 2)
#assert.eq(bucket-by-col(rows, "x").at(1).map(r => r.y), (2, 4))

// Facet panels get a trailing NA panel.
#assert.eq(
  _raw-levels-for(
    (layers: ((data: none),), data: ((g: "b"), (g: none), (g: "a"))),
    "g",
  ),
  ("b", "a", NA-KEY),
)

// The oob pre-pass keeps a missing cell, or drops it under `na-translate:
// false`.
#let data = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: none), (x: 3, y: 3, g: "b"))
#let mapping = aes(x: "x", y: "y", colour: "g")
#let kept(scale) = {
  let trained = train(
    scales: scales(colour: scale),
    layers: ((mapping: mapping, data: data, name: "point"),),
    mapping: mapping,
    data: data,
    aesthetics: ("x", "y", "colour"),
  )
  let layer = (kind: "layer", data: data, mapping: (colour: "g"))
  let out = filter-oob((layer,), oob-plans((colour: trained.colour)))
  out.layers.at(0).data.len()
}
#assert.eq(kept(scale-discrete(na-translate: false)), 2)
#assert.eq(kept(scale-discrete(limits: ("a", "b"))), 3)
