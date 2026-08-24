// A discrete scale requires its `limits` to be level names, as strings.
//
// A discrete scale reads a bare number as a 1-indexed position rather than a
// level name, so a numeric level would be ambiguous: the out-of-range pre-pass
// could not censor against it, and a position and a level of the same value
// would disagree. A domain trained from data is stringified, so only a user
// limit can carry another type.
//
// The failure itself cannot be asserted here, because Typst has no try/catch.
// This file pins the working shape, that quoted levels train, censor, and
// resolve; `tests/errors/scale-discrete-limits-type.typ` pins the message a
// numeric level fails with.

#import "../../src/scale/train.typ": train
#import "../../src/scale/constructors.typ": scale-discrete
#import "../../src/scales.typ": scales
#import "../../src/aes.typ": aes
#import "../../src/utils/level-resolve.typ": discrete-index
#import "../../src/scale/oob.typ": filter-oob

#let data = (
  (x: 1, y: 1, g: "10"),
  (x: 2, y: 2, g: "20"),
  (x: 3, y: 3, g: "90"),
)
#let mapping = aes(x: "x", y: "y", colour: "g")

#let trained = train(
  scales: scales(colour: scale-discrete(limits: ("10", "20"), oob: "drop")),
  layers: ((mapping: mapping, data: data, name: "point"),),
  mapping: mapping,
  data: data,
  aesthetics: ("x", "y", "colour"),
)

#assert.eq(trained.colour.type, "discrete")
#assert.eq(trained.colour.domain, ("10", "20"))

// The level name and its position differ here, which is the case that would
// hide a disagreement between the two readings.
#assert.eq(discrete-index(trained.colour, "10"), 0)
#assert.eq(discrete-index(trained.colour, "20"), 1)
#assert.eq(discrete-index(trained.colour, "90"), none)

// The pre-pass keeps every row here, and that is the documented rule rather
// than an accident: it reads any value that parses as a number as a position
// between levels, which a jittered point or a polygon vertex relies on. A level
// name that looks like a number therefore cannot be censored. That trade-off
// predates this file and is tracked separately.
#let layer = (kind: "layer", data: data, mapping: (colour: "g"))
#let out = filter-oob((layer,), (colour: trained.colour))
#assert.eq(out.layers.at(0).data.len(), 3)
#assert.eq(out.counts, (:))

// A level name that does not parse as a number is censored as expected.
#let named = ((g: "keep"), (g: "drop-me"))
#let named-trained = train(
  scales: scales(colour: scale-discrete(limits: ("keep",), oob: "drop")),
  layers: ((mapping: aes(colour: "g"), data: named, name: "point"),),
  mapping: aes(colour: "g"),
  data: named,
  aesthetics: ("x", "y", "colour"),
)
#let named-out = filter-oob(
  ((kind: "layer", data: named, mapping: (colour: "g")),),
  (colour: named-trained.colour),
)
#assert.eq(named-out.layers.at(0).data, ((g: "keep"),))
#assert.eq(named-out.counts.at("colour"), 1)

discrete limits tests passed.
