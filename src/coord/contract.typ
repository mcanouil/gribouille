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
// `project` reads both through `ctx.coord`, so a coord that overrides them
// reshapes `project` without overriding it too.
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
    let u = map-position(xt, xv, (ctx.coord.axis-range)(ctx, "x"))
    let v = map-position(yt, yv, (ctx.coord.axis-range)(ctx, "y"))
    if u == none or v == none { return none }
    (ctx.coord.to-canvas)(ctx, u, v)
  },
)
