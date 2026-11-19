// Training appends one trailing missing level when a discrete column holds a
// missing cell (`none` or `""`), after the data levels or the user `limits`.
// A column with no missing cell trains exactly as before.

#import "../../src/scale/train.typ": _train-entry, train
#import "../../src/scale/constructors.typ": scale-discrete
#import "../../src/scales.typ": scales
#import "../../src/aes.typ": aes
#import "../../src/utils/types.typ": MISSING-KEY

#let _train(data, scale: none, mapping: aes(x: "x", y: "y", colour: "g")) = {
  let sc = if scale == none { scales() } else { scales(colour: scale) }
  train(
    scales: sc,
    layers: ((mapping: mapping, data: data, name: "point"),),
    mapping: mapping,
    data: data,
    aesthetics: ("x", "y", "colour"),
  ).colour
}

#let rows(values) = values.map(g => (x: 1, y: 1, g: g))

#let t = _train(rows(("m", none, "f", "")))
#assert.eq(t.domain, ("f", "m", MISSING-KEY))
#assert.eq(t.missing-level, true)
#assert.eq(t.level-index.at(MISSING-KEY), 2)

#let t = _train(rows(("m", "f")))
#assert.eq(t.domain, ("f", "m"))
#assert.eq(t.missing-level, false)

#let t = _train(
  rows(("m", none, "f")),
  scale: scale-discrete(limits: ("m", "f")),
)
#assert.eq(t.domain, ("m", "f", MISSING-KEY))
#assert.eq(t.missing-level, true)

// Two cached columns, only one with a missing cell: one missing level.
#let two = train(
  scales: scales(),
  layers: (
    (
      mapping: aes(x: "x", y: "y", colour: "g"),
      data: rows(("m", "f")),
      name: "point",
    ),
    (
      mapping: aes(x: "x", y: "y", colour: "h"),
      data: ((x: 1, y: 1, h: none), (x: 1, y: 1, h: "f")),
      name: "point",
    ),
  ),
  mapping: none,
  data: none,
  aesthetics: ("x", "y", "colour"),
).colour
#assert.eq(two.domain, ("f", "m", MISSING-KEY))
#assert.eq(two.domain.filter(l => l == MISSING-KEY).len(), 1)

// `missing-translate: false` leaves the missing cell without a level.
#let cached = (
  cols: (
    (
      values: ("m", none, "f"),
      forced-type: none,
      levels: none,
    ),
  ),
  typst-mark: false,
)
#let off = _train-entry(
  "colour",
  cached,
  (type: "discrete", missing-translate: false),
)
#assert.eq(off.domain, ("f", "m"))
#assert.eq(off.missing-level, false)
#let on = _train-entry("colour", cached, (type: "discrete"))
#assert.eq(on.domain, ("f", "m", MISSING-KEY))

// The same through the public constructor.
#let t = _train(
  rows(("m", none, "f")),
  scale: scale-discrete(missing-translate: false),
)
#assert.eq(t.domain, ("f", "m"))
#assert.eq(t.missing-level, false)

// A column rewritten to its level spine records `MISSING-KEY` among its levels. It
// counts as a missing cell, so the domain holds one trailing missing level, even
// when a second layer maps the same axis with raw missing cells.
#let spine = "_gribouille-pos-g"
#let rewritten = (
  mapping: aes(x: spine, y: "y"),
  data: ((y: 1, "_gribouille-pos-g": 1), (y: 2, "_gribouille-pos-g": 3)),
  name: "point",
  _factor-levels: ("_gribouille-pos-g": ("a", "b", MISSING-KEY)),
)
#let raw-layer = (
  mapping: aes(x: spine, y: "y"),
  data: ((y: 1, "_gribouille-pos-g": none),),
  name: "point",
  _factor-levels: ("_gribouille-pos-g": ("a", "b", MISSING-KEY)),
)
#let spine-trained = train(
  scales: scales(),
  layers: (rewritten, raw-layer),
  mapping: none,
  data: none,
  aesthetics: ("x", "y"),
).x
#assert.eq(spine-trained.domain, ("a", "b", MISSING-KEY))
#assert.eq(spine-trained.missing-level, true)

// A layer whose data lacks the column adds no missing level.
#let absent = train(
  scales: scales(),
  layers: (
    (
      mapping: aes(x: "x", y: "y", colour: "g"),
      data: rows(("m", "f")),
      name: "point",
    ),
    (
      mapping: aes(x: "x", y: "y", colour: "g"),
      data: ((x: 1, y: 1),),
      name: "point",
    ),
  ),
  mapping: none,
  data: none,
  aesthetics: ("x", "y", "colour"),
).colour
#assert.eq(absent.domain, ("f", "m"))
