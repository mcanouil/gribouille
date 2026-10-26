// The shared shape of every coord. The renderer calls these functions rather
// than reading the coord name, so each constructor overrides only the steps
// that differ from the cartesian defaults.

#import "../scale/train.typ": map-position
#import "expand.typ": apply-expand

// `train` rewrites the trained positional scales once scale training is done,
// and `panel-size` turns the box the chrome leaves into the inner panel size.
// The default `train` applies the scale expansion that every coord shares.
//
// `frame` builds the bundle the panel hands geoms as `ctx.radial`, `none` on a
// cartesian panel. `axis-range` is the canvas range one axis maps into, and
// `to-canvas` turns a pair of mapped axis positions into a canvas point.
// `project` runs once per row, so the default reads `ctx.px-range` and
// `ctx.py-range` directly rather than calling `axis-range` and `to-canvas`.
// A coord that overrides either of them must override `project` too.
#let coord-base(name) = (
  kind: "coord",
  name: name,
  flipped: false,
  train: apply-expand,
  panel-size: (trained, w, h) => (w, h),
  frame: (
    x-trained,
    y-trained,
    px-range,
    py-range,
    label-bounds: (),
    tick-cm: 0.0,
  ) => none,
  axis-range: (ctx, axis) => if axis == "x" { ctx.px-range } else {
    ctx.py-range
  },
  to-canvas: (ctx, u, v) => (u, v),
  project: (ctx, xv, yv) => {
    let xt = ctx.trained.at("x", default: none)
    let yt = ctx.trained.at("y", default: none)
    if xt == none or yt == none { return none }
    let cx = map-position(xt, xv, ctx.px-range)
    let cy = map-position(yt, yv, ctx.py-range)
    if cx == none or cy == none { return none }
    (cx, cy)
  },
)
