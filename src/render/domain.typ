// Domain scanning, coordinate-system application, and post-training domain
// fix-ups (bar-zero floor, geom extents, ribbon padding, expansion, flip).

#import "../scale/train.typ": transform-fwd
#import "../scale/expansion.typ": DISCRETE-AUTO-DATA-PAD, normalise-expansion
#import "../utils/radial.typ": radial-axis-of
#import "../utils/types.typ": parse-number
#import "common.typ": _track-min-max
#import "../geom/registry.typ": GEOMS
#import "../stat/apply.typ": stat-flush

// Fold the ribbon y-range, so `ymin`/`ymax` extend the trained y domain.
#let _scan-rows(mapping, layer-data, acc) = {
  let ymin-col = if mapping == none { none } else {
    mapping.at("ymin", default: none)
  }
  let ymax-col = if mapping == none { none } else {
    mapping.at("ymax", default: none)
  }
  if ymin-col == none and ymax-col == none { return acc }
  for row in layer-data {
    for col in (ymin-col, ymax-col) {
      if col == none { continue }
      let v = parse-number(row.at(col, default: none))
      if v == none { continue }
      let (lo, hi) = _track-min-max(acc.ribbon-y-min, acc.ribbon-y-max, v)
      acc.ribbon-y-min = lo
      acc.ribbon-y-max = hi
    }
  }
  acc
}

// Single-pass classifier feeding `_post-train`. Only ribbon layers need a
// row scan; every other layer is classified from its name and parameters.
#let _post-train-scan(layers) = {
  let acc = (
    needs-y-zero: false,
    flush: false,
    any-fill: false,
    bar-half: 0,
    ribbon-y-min: none,
    ribbon-y-max: none,
  )
  for layer in layers {
    let geom = layer.at("name", default: "")
    let mapping = layer.at("mapping", default: none)

    if geom == "col" or geom == "area" { acc.needs-y-zero = true }
    if stat-flush(layer.at("stat-source", default: "identity")) {
      acc.flush = true
    }
    if geom == "col" {
      if layer.at("position", default: "identity") == "fill" {
        acc.any-fill = true
      }
      let bar-frac = layer.at("params", default: (:)).at("width", default: 0.9)
      acc.bar-half = calc.max(acc.bar-half, bar-frac / 2)
    }
    acc = _scan-rows(mapping, layer.at("data", default: ()), acc)
  }
  acc
}

// Inject labels `x`/`y`/... names into trained scale specs so axis and legend
// titles follow labels() overrides. `auto` (the labels default) keeps the
// scale-derived name; `none` sets `spec.blank` to suppress the title and
// collapse its reserved space; a string overrides the name.
#let _apply-labels(trained, labels) = {
  if labels == none { return trained }
  for (aes-name, label) in labels.axes.pairs() {
    if label == auto { continue }
    let t = trained.at(aes-name, default: none)
    if t == none { continue }
    let spec = t.at("spec", default: none)
    let base = if spec == none { (aesthetic: aes-name) } else { spec }
    let new-spec = if label == none {
      base + (blank: true)
    } else {
      base + (name: label)
    }
    let new-t = t
    new-t.insert("spec", new-spec)
    trained.insert(aes-name, new-t)
  }
  trained
}

// coord-transform warps the view at mapping time. Skips axes whose scale
// already pre-transformed the data: pre- and post-stat warps don't compose.
#let _apply-coord-transform(trained, coord) = {
  if coord == none or coord.at("name", default: none) != "transform" {
    return trained
  }
  for axis in ("x", "y") {
    let t = coord.at(axis, default: "identity")
    if t == "identity" { continue }
    let entry = trained.at(axis, default: none)
    if entry == none or entry.type != "continuous" { continue }
    if entry.at("pre-transformed", default: false) { continue }
    let new-entry = entry
    new-entry.insert("transform", t)
    trained.insert(axis, new-entry)
  }
  trained
}

// x-limits/y-limits arrive in data space; pre-transformed domains live in stat space.
#let _coord-limits-to-domain(entry, lim) = {
  if not entry.at("pre-transformed", default: false) { return lim }
  let t = entry.at("transform", default: "identity")
  let (lo, hi) = lim
  (transform-fwd(t, lo), transform-fwd(t, hi))
}

// coord-cartesian x-limits/y-limits overrides take precedence over scale training,
// so re-apply them after any per-panel retraining.
#let _apply-coord(trained, coord) = {
  if coord == none { return trained }
  if coord.name != "cartesian" { return trained }
  let x-limits = coord.at("x-limits", default: none)
  if (
    x-limits != none
      and trained.at("x", default: none) != none
      and trained.x.type == "continuous"
  ) {
    let new-x = trained.x
    new-x.insert("domain", _coord-limits-to-domain(trained.x, x-limits))
    trained.insert("x", new-x)
  }
  let y-limits = coord.at("y-limits", default: none)
  if (
    y-limits != none
      and trained.at("y", default: none) != none
      and trained.y.type == "continuous"
  ) {
    let new-y = trained.y
    new-y.insert("domain", _coord-limits-to-domain(trained.y, y-limits))
    trained.insert("y", new-y)
  }
  trained
}

// Detect whether the spec asks for axis-flipping at render time.
#let _is-flipped(coord) = (
  coord != none and coord.at("name", default: none) == "flip"
)

// The positional aesthetics that move to the other axis with `_apply-flip`, as
// `(x-side, y-side)` pairs. A geom reads these names against the swapped
// trained scales, so each pair listed here swaps with them. A channel left out
// stays in user space, so its geom draws correctly only if it branches on
// `ctx.flipped` itself.
#let _FLIP-PAIRS = (
  ("x", "y"),
  ("xend", "yend"),
  ("xmin", "ymin"),
  ("xmax", "ymax"),
)

// Swap each `_FLIP-PAIRS` entry of a layer mapping, keys and all: a key is
// present after the swap only if its partner was present before. A geom that
// reads `mapping.x` directly still finds the key `aes()` held as `none`, and a
// geom that reads an absent key with `default:` still gets its default.
#let _flip-mapping(mapping) = {
  if mapping == none { return none }
  let out = mapping
  for (x-side, y-side) in _FLIP-PAIRS {
    let has-x = x-side in mapping
    let has-y = y-side in mapping
    let x-col = out.remove(x-side, default: none)
    let y-col = out.remove(y-side, default: none)
    if has-y { out.insert(x-side, y-col) }
    if has-x { out.insert(y-side, x-col) }
  }
  out
}

// Swap the trained x and y scales so the renderer's bottom axis shows the
// user's original y scale and the left axis shows the user's original x
// scale. Called after `_apply-coord` so any cartesian x-limits/y-limits overrides
// apply to the pre-flip axes as the user wrote them.
#let _apply-flip(trained, coord) = {
  if not _is-flipped(coord) { return trained }
  let x = trained.at("x", default: none)
  let y = trained.at("y", default: none)
  trained.insert("x", y)
  trained.insert("y", x)
  if x == none { return trained }

  let policy = coord.at("reverse", default: auto)
  let do-reverse = if policy == auto { x.type == "discrete" } else { policy }
  if not do-reverse { return trained }
  let new-y = x
  if x.type == "discrete" {
    new-y.insert("reverse", true)
  } else if x.type == "continuous" {
    new-y.insert("reverse", not new-y.at("reverse", default: false))
  }
  trained.insert("y", new-y)
  trained
}

// Shrink the inner panel along the longer axis so that one x data unit
// projects to `ratio` y data units. Returns the adjusted (width, height).
// Falls back to the input box if either trained scale is missing or has a
// zero-length domain.
#let _fixed-inner-size(coord, trained, box-w, box-h) = {
  if coord == none or coord.name != "fixed" { return (box-w, box-h) }
  let x-trained = trained.at("x", default: none)
  let y-trained = trained.at("y", default: none)
  if x-trained == none or y-trained == none { return (box-w, box-h) }
  if x-trained.type != "continuous" or y-trained.type != "continuous" {
    return (box-w, box-h)
  }
  let (x-lo, x-hi) = x-trained.domain
  let (y-lo, y-hi) = y-trained.domain
  let dx = x-hi - x-lo
  let dy = y-hi - y-lo
  // A degenerate domain has no ratio to hold, and a box the chrome squeezed to
  // nothing has none either: hand the box back rather than divide by it.
  if dx <= 0 or dy <= 0 or box-w <= 0 or box-h <= 0 { return (box-w, box-h) }
  let ratio = coord.at("ratio", default: 1)
  // Pixels-per-x-unit must equal ratio * pixels-per-y-unit.
  let want = (dy * ratio) / dx
  let have = box-h / box-w
  if want >= have {
    (box-h / want, box-h)
  } else {
    (box-w, box-w * want)
  }
}

// Apply scale expansion on top of the already-padded domain produced by
// `_post-train`. Multiplicative breathing room (ratio) is folded into
// `view-transform` (continuous) / `view-index` (discrete); absolute additive
// padding (length) is recorded as `view-pad-cm` and applied later by
// `_draw-axis-and-layers` as a canvas-cm inset on the data area.
// `coord-cartesian(expand: false)` zeroes everything.
#let _apply-expand(trained, coord) = {
  let coord-no-expand = (
    coord != none
      and coord.at("name", default: none) == "cartesian"
      and coord.at("expand", default: true) == false
  )
  // Under `coord-radial`, the radial axis maps view-min to canvas radius 0,
  // so any lo-side padding leaves a hole at the centre. Collapse the radial
  // lo-side to zero when `expand` is auto.
  let radial-axis = radial-axis-of(coord)
  for axis in ("x", "y") {
    let entry = trained.at(axis, default: none)
    if entry == none { continue }
    let spec = entry.at("spec", default: none)
    let raw = if spec == none { auto } else { spec.at("expand", default: auto) }
    let expand = if coord-no-expand { false } else { raw }
    let (mult-lo, add-cm-lo, mult-hi, add-cm-hi) = normalise-expansion(
      expand,
      entry.type,
    )
    // A side left at `auto` (whole value or one tuple element) gets the
    // auto-only treatments below; an explicit value on that side opts out.
    let lo-auto = (
      raw == auto
        or (
          type(raw) == array and raw.len() == 2 and raw.at(0) == auto
        )
    )
    let hi-auto = (
      raw == auto
        or (
          type(raw) == array and raw.len() == 2 and raw.at(1) == auto
        )
    )
    // Bars / areas anchor at y=0: when the user did not pin `expand`
    // explicitly, drop the multiplicative expansion on the anchored side so
    // the baseline sits flush against the axis line. Length-add is always
    // honoured.
    let anchor = entry.at("anchor-zero", default: none)
    if anchor != none {
      if (anchor == "lo" or anchor == "both") and lo-auto { mult-lo = 0 }
      if (anchor == "hi" or anchor == "both") and hi-auto { mult-hi = 0 }
    }
    // A `flush` axis drops the automatic expansion on each side left at
    // `auto`, the same as `coord-cartesian(expand: false)` there.
    if entry.at("flush", default: false) {
      if lo-auto {
        mult-lo = 0
        add-cm-lo = 0
      }
      if hi-auto {
        mult-hi = 0
        add-cm-hi = 0
      }
    }
    let radial-zero-lo = axis == radial-axis and lo-auto
    if radial-zero-lo {
      mult-lo = 0
      add-cm-lo = 0
    }
    let new-entry = entry
    if entry.type == "continuous" {
      let (lo, hi) = entry.domain
      let transform = entry.at("transform", default: "identity")
      let pre = entry.at("pre-transformed", default: false)
      // Pre-transformed domains already live in stat space; warping again
      // would double-apply.
      let t-lo = if pre { lo } else { transform-fwd(transform, lo) }
      let t-hi = if pre { hi } else { transform-fwd(transform, hi) }
      let span = t-hi - t-lo
      new-entry.insert(
        "view-transform",
        (t-lo - mult-lo * span, t-hi + mult-hi * span),
      )
    } else if entry.type == "discrete" {
      let n = entry.domain.len()
      let span = if n > 1 { n - 1 } else { 0 }
      // A discrete side left at `auto` gets a default 0.6-slot data-unit pad;
      // an explicit value on that side supersedes it. Radial axes skip
      // the lo-side data pad so the inner edge sits at radius 0.
      let auto-data-pad-lo = if lo-auto { DISCRETE-AUTO-DATA-PAD } else { 0 }
      let auto-data-pad-hi = if hi-auto { DISCRETE-AUTO-DATA-PAD } else { 0 }
      let geom-min = entry.at("geom-min-pad", default: 0)
      let lo-pad-base = if radial-zero-lo { 0 } else { auto-data-pad-lo }
      let pad-lo = calc.max(mult-lo * span + lo-pad-base, geom-min)
      let pad-hi = calc.max(mult-hi * span + auto-data-pad-hi, geom-min)
      new-entry.insert("view-index", (0 - pad-lo, (n - 1) + pad-hi))
    }
    new-entry.insert("view-pad-cm", (add-cm-lo, add-cm-hi))
    trained.insert(axis, new-entry)
  }
  trained
}

// Rewrite a continuous trained-scale's domain via `fn((lo, hi)) -> (lo, hi)`.
// No-ops when the axis is missing or non-continuous.
#let _rewrite-continuous-domain(trained, axis, fn) = {
  let t = trained.at(axis, default: none)
  if t == none or t.type != "continuous" { return trained }
  let new = t
  new.insert("domain", fn(t.domain))
  trained.insert(axis, new)
  trained
}

// Widen a continuous axis to cover `(ext-lo, ext-hi)`. A missing axis is
// seeded as continuous with that range, for a geom such as ellipse that maps
// no `x`/`y` of its own; a discrete axis is left as is.
#let _extend-domain(trained, axis, ext-lo, ext-hi) = {
  if trained.at(axis, default: none) == none {
    trained.insert(axis, (
      type: "continuous",
      domain: (ext-lo, ext-hi),
      spec: none,
      transform: "identity",
      typst-mark: false,
    ))
    return trained
  }
  _rewrite-continuous-domain(trained, axis, ((lo, hi)) => (
    calc.min(lo, ext-lo),
    calc.max(hi, ext-hi),
  ))
}

// Apply post-training domain fix-ups (bar-zero floor, geom extents, ribbon
// ymin/ymax padding, discrete bar padding). Called once globally and once
// per panel under free scales so each panel's domain reflects its own subset.
#let _post-train(trained, layers) = {
  let scan = _post-train-scan(layers)

  // Bars and areas anchor against y=0. The touching side is tagged so
  // `_apply-expand` collapses its auto-expansion to zero, matching the
  // `expansion(mult = c(0, 0.05))` convention. `position: "fill"` anchors
  // both sides; mixed-sign data keeps symmetric expansion.
  if scan.needs-y-zero {
    let yt = trained.at("y", default: none)
    if yt != none and yt.type == "continuous" {
      let (lo, hi) = yt.domain
      let new-y = yt
      new-y.insert("domain", (calc.min(lo, 0.0), calc.max(hi, 0.0)))
      let anchor = if scan.any-fill {
        "both"
      } else if lo >= 0 {
        "lo"
      } else if hi <= 0 {
        "hi"
      } else { none }
      if anchor != none { new-y.insert("anchor-zero", anchor) }
      trained.insert("y", new-y)
    }
  }

  // Each geom with a `spec.extents` hook widens the continuous position
  // domains to the outer edges of its marks. The hook runs once per layer
  // on values in the trained-domain space; discrete axes ignore it, an
  // axis with user `limits` keeps them, reversed or narrow alike, and a
  // missing axis is seeded from the extents.
  let has-limits = (:)
  for axis in ("x", "y") {
    let t = trained.at(axis, default: none)
    let spec = if t == none { none } else { t.at("spec", default: none) }
    has-limits.insert(
      axis,
      spec != none and spec.at("limits", default: none) != none,
    )
  }
  for layer in layers {
    let extents = GEOMS
      .at(layer.at("name", default: ""), default: (spec: (extents: none)))
      .spec
      .extents
    let mapping = layer.at("mapping", default: none)
    if extents == none or mapping == none { continue }
    let ext = extents(
      layer.at("params", default: (:)),
      mapping,
      layer.at("data", default: ()),
    )
    for axis in ("x", "y") {
      let range = ext.at(axis, default: none)
      if range == none or has-limits.at(axis) { continue }
      let (ext-lo, ext-hi) = range
      trained = _extend-domain(trained, axis, ext-lo, ext-hi)
    }
  }

  if scan.ribbon-y-min != none {
    let lo-extra = scan.ribbon-y-min
    let hi-extra = scan.ribbon-y-max
    trained = _rewrite-continuous-domain(trained, "y", ((lo, hi)) => (
      calc.min(lo, lo-extra),
      calc.max(hi, hi-extra),
    ))
  }

  // Discrete category axes get `geom-min-pad` so `_apply-expand` keeps outer
  // bars inside the panel; the continuous case is col's extents hook.
  if scan.bar-half > 0 {
    let xt = trained.at("x", default: none)
    if xt != none and xt.type == "discrete" {
      let new-x = xt
      new-x.insert("geom-min-pad", scan.bar-half)
      trained.insert("x", new-x)
    }
  }

  // A `flush` stat tags both position axes so `_apply-expand` drops their
  // automatic expansion.
  if scan.flush {
    for axis in ("x", "y") {
      let t = trained.at(axis, default: none)
      if t == none { continue }
      t.insert("flush", true)
      trained.insert(axis, t)
    }
  }

  trained
}
