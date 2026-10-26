// The shared shape of every coord. The renderer calls these functions rather
// than reading the coord name, so each constructor overrides only the steps
// that differ from the cartesian defaults.

#import "expand.typ": apply-expand

// `train` rewrites the trained positional scales once scale training is done,
// and `panel-size` turns the box the chrome leaves into the inner panel size.
// The default `train` applies the scale expansion that every coord shares.
#let coord-base(name) = (
  kind: "coord",
  name: name,
  flipped: false,
  train: apply-expand,
  panel-size: (trained, w, h) => (w, h),
)
