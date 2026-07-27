// A continuous scale trained on whole numbers keeps whole breaks: a narrow
// integer range (years, counts, a few epoch days) must not label half-steps.

#import "../../lib.typ": aes, geom-point, scale-date, scales
#import "../../src/scale/train.typ": train
#import "../../src/render/axis-format.typ": _axis-breaks
#import "../../src/render/domain.typ": _apply-expand
#import "../../src/render/legend.typ": guides-for
#import "../../src/utils/pretty.typ": pretty

#let layers = (geom-point(),)

// --- `pretty` only snaps to whole steps when asked ---

// The 5% expanded view of the years 2020..2023.
#assert.eq(
  pretty(2019.85, 2023.15, n: 5, integer: true),
  (2020.0, 2021.0, 2022.0, 2023.0),
)
#assert(pretty(2019.85, 2023.15, n: 5).any(b => b == 2020.5))

// A step already at or above 1 is untouched by the flag.
#assert.eq(pretty(0, 50, n: 5, integer: true), pretty(0, 50, n: 5))

// Binary data yields the two whole ticks rather than quarter-steps.
#assert.eq(pretty(0, 1, n: 5, integer: true), (0.0, 1.0))

// --- end to end: integer columns through `train` and expansion ---

#let years = (
  (x: 2020, y: 40),
  (x: 2021, y: 55),
  (x: 2022, y: 60),
  (x: 2023, y: 65),
)
#let trained-years = _apply-expand(
  train(layers: layers, mapping: aes(x: "x", y: "y"), data: years),
  none,
)
#assert(trained-years.x.integer)
#assert.eq(_axis-breaks(trained-years.x), (2020.0, 2021.0, 2022.0, 2023.0))

// Fractional columns keep the fine-grained breaks.
#let fractions = (
  (x: 1.5, y: 1),
  (x: 2.5, y: 2),
)
#let trained-fractions = train(
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: fractions,
)
#assert(not trained-fractions.x.integer)
#assert(_axis-breaks(trained-fractions.x).any(b => b != calc.round(b)))

// A single integer value widens to a half-unit domain; its break stays whole.
#let trained-single = train(
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: ((x: 2020, y: 1),),
)
#assert.eq(_axis-breaks(trained-single.x), (2020.0,))

// --- synthetic feeders fold into the flag ---

// A fractional `ymin` feeder re-enables fractional breaks on y, since the
// folded domain no longer describes whole numbers only.
#let ribbon-rows = (
  (x: 1, y: 3, lo: 0.5),
  (x: 2, y: 4, lo: 1.5),
)
#let trained-feeder = train(
  layers: layers,
  mapping: aes(x: "x", y: "y", ymin: "lo"),
  data: ribbon-rows,
)
#assert(not trained-feeder.y.integer)

// A whole-numbered feeder keeps it.
#let whole-rows = (
  (x: 1, y: 3, lo: 0),
  (x: 2, y: 4, lo: 1),
)
#let trained-whole-feeder = train(
  layers: layers,
  mapping: aes(x: "x", y: "y", ymin: "lo"),
  data: whole-rows,
)
#assert(trained-whole-feeder.y.integer)

// --- continuous guides follow the same rule ---

#let layer-point() = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: auto, fill: auto, shape: auto),
)

#let guide-breaks(aesthetic, trained-entry) = {
  let g = guides-for(
    (
      mapping: ((aesthetic): "z"),
      layers: (layer-point(),),
      guides: (:),
    ),
    ((aesthetic): trained-entry),
  )
  g.at(0).breaks
}

// A colourbar over whole-numbered data ticks whole values.
#assert.eq(
  guide-breaks(
    "fill",
    (type: "continuous", domain: (1, 4), spec: (:), integer: true),
  ),
  (1.0, 2.0, 3.0, 4.0),
)

// The size ladder shares the rule; fractional data keeps the fine ticks.
#assert.eq(
  guide-breaks(
    "size",
    (type: "continuous", domain: (1, 4), spec: (:), integer: true),
  ),
  (1.0, 2.0, 3.0, 4.0),
)
#assert(
  guide-breaks(
    "size",
    (type: "continuous", domain: (1, 4), spec: (:)),
  ).any(b => b != calc.round(b)),
)

// --- dates: four consecutive epoch days no longer repeat a label ---

#let days = (
  (x: 8766, y: 1),
  (x: 8767, y: 2),
  (x: 8768, y: 3),
  (x: 8769, y: 4),
)
#let trained-days = train(
  scales: scales(x: scale-date()),
  layers: layers,
  mapping: aes(x: "x", y: "y"),
  data: days,
)
#assert.eq(
  _axis-breaks(trained-days.x),
  (8766.0, 8767.0, 8768.0, 8769.0),
)
