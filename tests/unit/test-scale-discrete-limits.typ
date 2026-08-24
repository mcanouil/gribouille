// A discrete scale requires its `limits` to be level names, as strings.
//
// A discrete scale reads a bare number as a 1-indexed position rather than a
// level name, so a numeric level would be ambiguous: the out-of-range pre-pass
// could not censor against it, and a position and a level of the same value
// would disagree. A domain trained from data is stringified, so only a user
// limit can carry another type.
//
// The failure itself cannot be asserted here, because Typst has no try/catch.
// This pins the working shape: quoted levels train, censor, and resolve.

#import "../../src/scale/train.typ": train
#import "../../src/scale/constructors.typ": scale-discrete
#import "../../src/scales.typ": scales
#import "../../src/aes.typ": aes
#import "../../src/utils/level-resolve.typ": discrete-index
#import "../../src/scale/oob.typ": filter-oob, oob-plans

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

// A level name that looks like a number is still a level name, so the pre-pass
// censors it. The cell is the string "90", which the domain does not carry.
#let layer = (kind: "layer", data: data, mapping: (colour: "g"))
#let out = filter-oob((layer,), oob-plans((colour: trained.colour)))
#assert.eq(out.layers.at(0).data.map(row => row.g), ("10", "20"))
#assert.eq(out.counts.at("colour"), 1)

// A native number is a 1-indexed fractional level position rather than a level
// name, which is how `map-discrete` reads it, so the pre-pass keeps it. A
// jittered point and a polygon vertex both arrive as one, and the renderer can
// place them. The value here is off the two-level domain on purpose: what keeps
// it is its type, not its range.
#let placed = ((g: 1.5), (g: 90))
#let placed-out = filter-oob(
  ((kind: "layer", data: placed, mapping: (colour: "g")),),
  oob-plans((colour: trained.colour)),
)
#assert.eq(placed-out.layers.at(0).data, placed)
#assert.eq(placed-out.counts, (:))

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
  oob-plans((colour: named-trained.colour)),
)
#assert.eq(named-out.layers.at(0).data, ((g: "keep"),))
#assert.eq(named-out.counts.at("colour"), 1)

discrete limits tests passed.
