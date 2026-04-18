// Scale training and value-to-range mapping.
//
// Training walks every layer's data for the given aesthetic and computes
// the union domain. A continuous domain is (min, max); a discrete domain
// is the list of unique levels in order of first appearance.
//
// Mapping turns a trained domain plus a target range into a scalar position.

#import "../data.typ": column
#import "../utils/types.typ": parse-number, infer-column-type

#let _resolve-mapping(layer, plot-mapping) = {
  if layer.at("inherit-aes", default: true) and plot-mapping != none {
    let merged = plot-mapping
    if layer.mapping != none {
      for (k, v) in layer.mapping.pairs() {
        if v != none { merged.insert(k, v) }
      }
    }
    merged
  } else if layer.mapping != none {
    layer.mapping
  } else {
    plot-mapping
  }
}

#let _resolve-data(layer, plot-data) = {
  if layer.data != none { layer.data } else { plot-data }
}

// A mapping value is either a plain string (column name) or a mapping-ref
// annotation dict produced by `as-factor("col")` / `as-numeric("col")`.
// Return the column name either way.
#let mapping-ref-col(value) = {
  if type(value) == dictionary and value.at("kind", default: none) == "mapping-ref" {
    value.var
  } else {
    value
  }
}

// Return the forced type from a mapping-ref or `none` if not annotated.
#let mapping-ref-type(value) = {
  if type(value) == dictionary and value.at("kind", default: none) == "mapping-ref" {
    value.type
  } else {
    none
  }
}

#let _column-for-aesthetic(layer, aesthetic, plot-mapping, plot-data) = {
  let mapping = _resolve-mapping(layer, plot-mapping)
  let data = _resolve-data(layer, plot-data)
  if mapping == none { return none }
  let raw = mapping.at(aesthetic, default: none)
  if raw == none { return none }
  let col-name = mapping-ref-col(raw)
  (name: col-name, values: column(data, col-name), forced-type: mapping-ref-type(raw))
}

#let train-continuous(layers, aesthetic, plot-mapping, plot-data) = {
  let all-vals = ()
  for layer in layers {
    let col = _column-for-aesthetic(layer, aesthetic, plot-mapping, plot-data)
    if col == none { continue }
    let numeric = col.values.map(parse-number).filter(v => v != none)
    all-vals += numeric
  }
  if all-vals.len() == 0 { return (0.0, 1.0) }
  let lo = calc.min(..all-vals)
  let hi = calc.max(..all-vals)
  if lo == hi { return (lo - 0.5, hi + 0.5) }
  (lo, hi)
}

#let train-discrete(layers, aesthetic, plot-mapping, plot-data) = {
  let seen = ()
  for layer in layers {
    let col = _column-for-aesthetic(layer, aesthetic, plot-mapping, plot-data)
    if col == none { continue }
    for v in col.values {
      if v == none or v == "" { continue }
      let s = str(v)
      if not seen.contains(s) { seen.push(s) }
    }
  }
  seen
}

#let _layer-aesthetic-type(layers, aesthetic, plot-mapping, plot-data) = {
  for layer in layers {
    let col = _column-for-aesthetic(layer, aesthetic, plot-mapping, plot-data)
    if col == none { continue }
    if col.forced-type != none { return col.forced-type }
    let t = infer-column-type(col.values)
    return if t == "numeric" { "continuous" } else { "discrete" }
  }
  "continuous"
}

#let _find-user-scale(scales, aesthetic) = {
  for s in scales {
    if s.aesthetic == aesthetic { return s }
  }
  none
}

#let train(scales: (), layers: (), mapping: none, data: none) = {
  let trained = (:)
  let aesthetics = (
    "x", "y",
    "colour", "fill", "size", "alpha",
    "shape", "linetype",
    "xmin", "xmax", "ymin", "ymax",
    "xend", "yend",
  )
  for a in aesthetics {
    let user-scale = _find-user-scale(scales, a)
    let mapped = layers.any(layer => {
      let m = _resolve-mapping(layer, mapping)
      m != none and m.at(a, default: none) != none
    })
    if not mapped and user-scale == none { continue }
    let scale-type = if user-scale != none {
      user-scale.type
    } else {
      _layer-aesthetic-type(layers, a, mapping, data)
    }
    let domain = if scale-type == "continuous" {
      train-continuous(layers, a, mapping, data)
    } else {
      train-discrete(layers, a, mapping, data)
    }
    if user-scale != none and user-scale.at("limits", default: none) != none {
      domain = user-scale.limits
    }
    trained.insert(a, (type: scale-type, domain: domain, spec: user-scale))
  }
  trained
}

#let map-continuous(value, domain, range) = {
  let (d-lo, d-hi) = domain
  let (r-lo, r-hi) = range
  if d-hi == d-lo { return (r-lo + r-hi) / 2 }
  let t = (value - d-lo) / (d-hi - d-lo)
  r-lo + t * (r-hi - r-lo)
}

#let map-discrete(value, domain, range) = {
  let s = str(value)
  let idx = domain.position(v => v == s)
  let n = domain.len()
  if idx == none or n == 0 { return none }
  let (r-lo, r-hi) = range
  if n == 1 { return (r-lo + r-hi) / 2 }
  r-lo + (idx + 0.5) * (r-hi - r-lo) / n
}

#let map-position(trained, value, range) = {
  if trained.type == "continuous" {
    let v = parse-number(value)
    if v == none { return none }
    map-continuous(v, trained.domain, range)
  } else {
    map-discrete(value, trained.domain, range)
  }
}
