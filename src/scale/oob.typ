// Out-of-range pre-pass.
//
// Walks each prepared layer once after training and removes rows whose value
// for any user-limited aesthetic falls outside the trained domain. When the
// scale's `oob` is `"squish"` the row stays and the cell is clamped to the
// nearest limit so downstream resolvers see an in-range value. Discrete
// scales censor only — squish has no geometric meaning on levels.

#import "../utils/types.typ": parse-number
#import "../utils/late-binding.typ": is-late-binding
#import "train.typ": mapping-ref-col, transform-fwd, view-bounds-stat
#import "../utils/errors.typ": fail

// Build the per-row check for one trained scale, or `none` when the scale sets
// no user `limits` and therefore censors nothing.
//
// The check is a closure taking the cell alone. Everything else it needs is
// captured rather than passed, because an argument that reaches a long array
// costs time proportional to its length on every call, while a captured scope
// is shared by reference and costs nothing. This is the same measured cost the
// per-row `layer` argument carried before it was hoisted out.
//
// Capture is what buys the saving, not the faster level test. Measured over
// twenty thousand rows, with both arms already testing the level through a
// dict lookup rather than a scan: carrying the levels in a plain record kept
// the cost growing with the level count (0.29 s at fifty levels, 1.17 s at two
// thousand), while capturing them in a closure is flat (0.26 s and 0.31 s).
// The record still reaches every level, so the row walk keeps paying for them.
//
// The closure returns one of:
//   ("in",     value)   — unchanged
//   ("squish", clamped) — kept, value rewritten
//   ("drop",   value)   — caller drops the row
#let _checker(trained) = {
  let spec = trained.at("spec", default: none)
  if spec == none { return none }
  let limits = spec.at("limits", default: none)
  if limits == none { return none }
  let oob = spec.at("oob", default: "drop")

  if trained.type == "continuous" {
    // The expanded view in stat space, rather than the raw `limits`, so a value
    // sitting in the expansion headroom -- which still maps inside the visible
    // panel -- survives instead of being dropped.
    let (t-lo, t-hi) = view-bounds-stat(trained)
    // `t-lo`/`t-hi` follow the domain order, which runs high-to-low when the
    // user supplies reversed `limits` to flip the axis; the in-range test reads
    // the sorted span so it holds either way.
    let span-lo = calc.min(t-lo, t-hi)
    let span-hi = calc.max(t-lo, t-hi)
    let (lo, hi) = trained.domain
    // The two fields `_to-stat` reads, so the row path warps the value without
    // reaching back into the trained scale.
    let pre-transformed = trained.at("pre-transformed", default: false)
    let transform = trained.at("transform", default: "identity")
    return (
      limits: limits,
      check: raw => {
        let v = parse-number(raw)
        if v == none { return ("in", raw) }
        let sv = if pre-transformed { v } else { transform-fwd(transform, v) }
        if sv >= span-lo and sv <= span-hi { return ("in", raw) }
        if oob == "squish" {
          // Clamp to the nearest `limits` endpoint (the visible data edge), not
          // the expanded bound, matching the documented squish-to-limit
          // semantics. `t-lo` pairs with `lo` and `t-hi` with `hi` whatever the
          // order.
          let to-lo = calc.abs(sv - t-lo) <= calc.abs(sv - t-hi)
          return ("squish", if to-lo { lo } else { hi })
        }
        ("drop", raw)
      },
    )
  }

  if trained.type == "discrete" {
    // `level-index` is the `(level: position)` dict every trained discrete
    // scale carries, so the level test is one lookup rather than a scan of the
    // domain. Fall back to the domain when it is absent, as `discrete-index`
    // does, since a hand-built trained dict carries no index.
    let levels = trained.at("level-index", default: none)
    let domain = trained.domain
    return (
      limits: limits,
      check: raw => {
        if raw == none { return ("in", raw) }
        // A numeric value addresses a 1-indexed fractional level position rather
        // than a level name (`map-discrete` places it at `value - 1`), e.g. a
        // polygon vertex set between level centres or a jittered point. The
        // renderer can place it, so the pre-pass keeps it and lets panel clipping
        // bound any overflow; drop fires only for a non-numeric value off the
        // set.
        if parse-number(raw) != none { return ("in", raw) }
        let s = str(raw)
        let known = if levels == none { domain.contains(s) } else {
          s in levels
        }
        if known { return ("in", raw) }
        ("drop", raw)
      },
    )
  }

  (limits: limits, check: raw => ("in", raw))
}

// Filter rows of every layer through the trained dict. Returns the rewritten
// layers and a per-aesthetic dropped-row count. `strict: true` converts the
// first drop into a `panic` instead.
#let filter-oob(layers, trained, strict: false) = {
  // Everything the check reads is constant per aesthetic, so each scale is
  // resolved once here into a closure the row walk calls with the cell alone.
  // Held as an array rather than a dict, so the row walk iterates it directly
  // instead of looking each aesthetic up again on every row.
  let active = ()
  for (aes, t) in trained.pairs() {
    let plan = _checker(t)
    if plan == none { continue }
    active.push((aes: aes, ..plan))
  }
  if active.len() == 0 { return (layers: layers, counts: (:)) }

  let counts = (:)
  let new-layers = ()
  for layer in layers {
    // A `clip: false` layer (e.g. `annotate(clip: false)`) is meant to draw
    // beyond the limits, so it opts out of the drop pre-pass entirely; its rows
    // pass through verbatim. Mirror the unclipped-set predicate in `panel-draw`
    // (`not layer.clip`) so the two passes agree on which layers are unclipped.
    if not layer.at("clip", default: true) {
      new-layers.push(layer)
      continue
    }
    let mapping = layer.at("mapping", default: none)
    let data = layer.at("data", default: none)
    if mapping == none or type(data) != array {
      new-layers.push(layer)
      continue
    }
    // Which column each limited aesthetic reads is a property of the layer, not
    // of the row, and `mapping-ref-col` walks the wrapper chain to find it.
    // Resolve it once per layer so the row walk only reads the cell.
    let bound = ()
    for plan in active {
      let raw = mapping.at(plan.aes, default: none)
      if raw == none { continue }
      if is-late-binding(raw) { continue }
      bound.push((col: mapping-ref-col(raw), ..plan))
    }
    if bound.len() == 0 {
      new-layers.push(layer)
      continue
    }
    let kept = ()
    for (row-idx, row) in data.enumerate() {
      let new-row = row
      let drop = false
      for plan in bound {
        let aes = plan.aes
        let col = plan.col
        let cell = row.at(col, default: none)
        let (action, value) = (plan.check)(cell)
        if action == "in" { continue }
        if action == "squish" {
          new-row.insert(col, value)
          continue
        }
        if strict {
          fail(
            "scale `" + aes + "`",
            "row "
              + str(row-idx)
              + " value "
              + repr(cell)
              + " outside limits "
              + repr(plan.limits),
            hint: "Set `oob: \"squish\"` to clamp, widen `limits`, "
              + "or remove `strict: true` to drop silently.",
          )
        }
        drop = true
        counts.insert(aes, counts.at(aes, default: 0) + 1)
        break
      }
      if not drop { kept.push(new-row) }
    }
    let new-layer = layer
    new-layer.data = kept
    new-layers.push(new-layer)
  }
  (layers: new-layers, counts: counts)
}
