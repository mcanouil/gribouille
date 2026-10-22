// Axis roles of the geoms that draw a range at a position: a vertical range
// at each x, or under coord-flip a horizontal range at each y. The renderer
// swaps the mapping keys and the trained scales under flip, so these geoms
// read the position from y and the range from x, and swap each canvas point.

#import "radial.typ": project-point

// Position, value, minimum, and maximum columns, read from the mapping keys
// that hold them on the drawn axes.
#let range-columns(mapping, flipped) = {
  let (pos, span) = if flipped { ("y", "x") } else { ("x", "y") }
  (
    pos: mapping.at(pos, default: none),
    value: mapping.at(span, default: none),
    min: mapping.at(span + "min", default: none),
    max: mapping.at(span + "max", default: none),
  )
}

// Trained scales and canvas ranges of the position and value axes, or `none`
// when either scale is missing.
#let range-axes(ctx) = {
  let flipped = ctx.at("flipped", default: false)
  let (pos, span) = if flipped { ("y", "x") } else { ("x", "y") }
  let pos-trained = ctx.trained.at(pos, default: none)
  let value-trained = ctx.trained.at(span, default: none)
  if pos-trained == none or value-trained == none { return none }
  (
    pos-trained: pos-trained,
    value-trained: value-trained,
    pos-range: if flipped { ctx.py-range } else { ctx.px-range },
    value-range: if flipped { ctx.px-range } else { ctx.py-range },
  )
}

// Canvas `(cx, cy)` of a point given in canvas units along the position and
// value axes.
#let range-canvas-point(flipped, pos-c, value-c) = if flipped {
  (value-c, pos-c)
} else {
  (pos-c, value-c)
}

// Canvas point of data `value` at data position `pos`.
#let project-range-point(ctx, pos, value) = if ctx.at(
  "flipped",
  default: false,
) {
  project-point(ctx, value, pos)
} else {
  project-point(ctx, pos, value)
}
