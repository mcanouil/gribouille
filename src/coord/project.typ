// The projection entry points geoms call. Each one routes through the coord
// carried in `ctx.coord`, so a geom never asks which coord it is drawn under.

#import "../scale/train.typ": map-axis, map-axis-data, map-position
#import "../utils/errors.typ": fail-enum

// Canvas `(cx, cy)` of a row's `(x, y)`, or `none` when either value does not
// resolve on its trained scale.
#let project-point(ctx, xv, yv) = (ctx.coord.project)(ctx, xv, yv)

// Canvas point of a pair of positions already mapped by `axis-mapper`.
#let to-canvas(ctx, u, v) = (ctx.coord.to-canvas)(ctx, u, v)

// Closure that maps one value of `axis` into the coord's range for that axis.
// The trained scale and the range are read once and captured, for a caller
// that maps many values off one axis. `space` names what the values are:
// `"row"` takes raw row cells and discrete levels (`map-position`), `"stat"`
// takes numbers already in stat space (`map-axis`), and `"data"` takes numbers
// in data space (`map-axis-data`).
#let axis-mapper(ctx, axis, space: "row") = {
  let map = if space == "row" { map-position } else if space == "stat" {
    map-axis
  } else if space == "data" { map-axis-data } else {
    fail-enum("axis-mapper", "space", space, ("row", "stat", "data"))
  }
  let trained = ctx.trained.at(axis, default: none)
  if trained == none { return value => none }
  let axis-range = (ctx.coord.axis-range)(ctx, axis)
  value => map(trained, value, axis-range)
}
