// A discrete scale accepts numeric `limits`.
//
// `limits` become the trained domain verbatim, and the level index is keyed by
// the stringified level, so a numeric level is reachable by its own string. The
// index used to be keyed by the raw value, which failed outright, because a
// Typst dictionary key must be a string.

#import "../../src/scale/train.typ": train
#import "../../src/scale/constructors.typ": scale-discrete
#import "../../src/scales.typ": scales
#import "../../src/aes.typ": aes
#import "../../src/utils/level-resolve.typ": discrete-index

#let data = ((x: 1, y: 1, g: 1), (x: 2, y: 2, g: 2))
#let mapping = aes(x: "x", y: "y", colour: "g")

#let trained = train(
  scales: scales(colour: scale-discrete(limits: (1, 2))),
  layers: ((mapping: mapping, data: data, name: "point"),),
  mapping: mapping,
  data: data,
  aesthetics: ("x", "y", "colour"),
)

#assert.eq(trained.colour.type, "discrete")
#assert.eq(trained.colour.domain, (1, 2))
#assert.eq(discrete-index(trained.colour, 1), 0)
#assert.eq(discrete-index(trained.colour, 2), 1)
#assert.eq(discrete-index(trained.colour, 3), none)

numeric discrete limits tests passed.
