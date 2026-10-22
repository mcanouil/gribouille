// A numeric-offset position (beeswarm, jitter, jitterdodge, nudge) writes each
// discrete level to a spine slot numbered in the layer's own sorted order.
// `_rebase-level-spine` moves every row to the slot its level holds on the
// trained scale of the panel, keeping the offset the position added, so the
// marks follow `limits` and the levels other layers add.

#import "../../src/render/prestat.typ": _rebase-level-spine

#let pos-col = "_gribouille-pos-g"
#let layer = (
  mapping: (x: pos-col, y: "v"),
  _factor-levels: ((pos-col): ("a", "b", "c")),
)
#let data = (
  (g: "a", v: 1, (pos-col): 1.2),
  (g: "b", v: 2, (pos-col): 1.9),
  (g: "c", v: 3, (pos-col): 3.0),
)
#let continuous = (type: "continuous", domain: (0, 3))

// --- limits reorder the domain: c, a, b ---------------------------------------
#let by-limits = _rebase-level-spine(
  data,
  layer,
  (x: (type: "discrete", domain: ("c", "a", "b")), y: continuous),
)
#assert.eq(by-limits.map(r => r.at(pos-col)), (2.2, 2.9, 1.0))
#assert.eq(by-limits.map(r => r.g), ("a", "b", "c"))

// --- another layer adds a level before the layer's own -----------------------
#let bc-layer = (
  mapping: (x: pos-col, y: "v"),
  _factor-levels: ((pos-col): ("b", "c")),
)
#let bc = ((g: "b", v: 2, (pos-col): 1.1), (g: "c", v: 3, (pos-col): 2.0))
#let union = _rebase-level-spine(
  bc,
  bc-layer,
  (x: (type: "discrete", domain: ("a", "b", "c")), y: continuous),
)
#assert.eq(union.map(r => r.at(pos-col)), (2.1, 3.0))

// --- a level the trained scale drops has no slot ------------------------------
#let dropped = _rebase-level-spine(
  data,
  layer,
  (x: (type: "discrete", domain: ("a", "b")), y: continuous),
)
#assert.eq(dropped.at(2).at(pos-col), none)

// --- under coord-flip the layer's x is drawn on the trained y -----------------
#let flipped = _rebase-level-spine(
  data,
  layer,
  (x: continuous, y: (type: "discrete", domain: ("c", "a", "b"))),
  flipped: true,
)
#assert.eq(flipped.map(r => r.at(pos-col)), (2.2, 2.9, 1.0))

// --- x and y on one source column share one spine, shifted once -------------
#let shared = _rebase-level-spine(
  data,
  (
    mapping: (x: pos-col, y: pos-col),
    _factor-levels: ((pos-col): ("a", "b", "c")),
  ),
  (
    x: (type: "discrete", domain: ("c", "a", "b")),
    y: (type: "discrete", domain: ("c", "a", "b")),
  ),
)
#assert.eq(shared.map(r => r.at(pos-col)), (2.2, 2.9, 1.0))

// --- a shared spine column is shifted by the first axis that is discrete -----
#let shared-y = _rebase-level-spine(
  data,
  (
    mapping: (x: pos-col, y: pos-col),
    _factor-levels: ((pos-col): ("a", "b", "c")),
  ),
  (x: continuous, y: (type: "discrete", domain: ("c", "a", "b"))),
)
#assert.eq(shared-y.map(r => r.at(pos-col)), (2.2, 2.9, 1.0))

// --- a layer without a spine is returned as is --------------------------------
#let plain = (mapping: (x: "g", y: "v"))
#assert.eq(
  _rebase-level-spine(data, plain, (x: continuous, y: continuous)),
  data,
)

level spine rebase tests passed.
