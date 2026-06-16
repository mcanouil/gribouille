// Bundled datasets carry the documented schema and `plot()` propagates
// the alt parameter through the spec so `get-alt-text` can recover it.

#import "../../src/datasets/economics.typ": economics
#import "../../src/datasets/mpg.typ": mpg
#import "../../src/datasets/penguins.typ": penguins
#import "../../src/plot.typ": get-alt-text, plot
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point

// Bundled datasets ship as row-store arrays so `.filter`/`.map` work directly;
// assert the shape and row count match what consumers (every geom and stat)
// see after `plot()` resolves the data.
#let assert-schema(data, count, columns) = {
  assert.eq(type(data), array, message: "expected row-store array")
  assert.eq(data.len(), count)
  let missing = columns.filter(col => not data.at(0).keys().contains(col))
  assert.eq(missing, (), message: "Missing columns: " + repr(missing))
}

#assert-schema(economics, 24, (
  "date",
  "pce",
  "pop",
  "psavert",
  "uempmed",
  "unemploy",
))
#assert.eq(economics.at(0).at("date"), "2008-01-01")

#assert-schema(mpg, 30, (
  "manufacturer",
  "model",
  "displ",
  "cyl",
  "class",
  "cty",
  "hwy",
))

#assert-schema(penguins, 344, (
  "species",
  "island",
  "bill-len",
  "bill-dep",
  "flipper-len",
  "body-mass",
  "sex",
  "year",
))
#assert.eq(penguins.at(0).at("species"), "Adelie")

// Row-store arrays support `.filter`/`.map` directly (the motivating case).
#assert.eq(penguins.filter(r => r.at("island") == "Biscoe").len(), 168)
#assert.eq(penguins.map(r => r.at("species")).first(), "Adelie")

// `plot()` returns rendered content, so exercise the spec contract via
// the accessor on a hand-built spec dict mirroring what `plot()` stores.
#let spec-with-alt = (
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (geom-point(),),
  alt: "An example plot",
)
#assert.eq(get-alt-text(spec-with-alt), "An example plot")

#let spec-without-alt = (
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (geom-point(),),
)
#assert.eq(get-alt-text(spec-without-alt), none)

// `plot()` accepts the alt parameter and renders without error.
#let _figure = plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (geom-point(size: 2pt),),
  alt: "An example plot",
  width: 6cm,
  height: 4cm,
)

Datasets and alt-text tests passed.
