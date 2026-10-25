// Turn the `coord` a spec carries into one the renderer can call. Kept apart
// from `contract.typ` because it builds the default `coord-cartesian()`, which
// itself imports the contract.

#import "../utils/errors.typ": fail
#import "cartesian.typ": coord-cartesian

#let resolve-coord(coord) = {
  if coord == none { return coord-cartesian() }
  if type(coord.at("train", default: none)) != function {
    fail(
      "plot",
      "coord must carry a callable `train`; got " + repr(coord),
      hint: "Build it with a `coord-*()` constructor, such as `coord-cartesian()`.",
    )
  }
  coord
}
