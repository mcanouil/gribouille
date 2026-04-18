// CeTZ rendering glue.
// Draws a single cartesian panel with axes and layer marks.

#import "@preview/cetz:0.5.0"
#import "scale/train.typ": train, map-continuous, map-position, mapping-ref-col
#import "stat/apply.typ": apply-stat
#import "position/apply.typ": apply-position
#import "theme/defaults.typ": merge-theme
#import "facet/wrap.typ" as facet-wrap-mod
#import "facet/shared.typ" as facet-shared
#import "utils/pretty.typ": pretty
#import "utils/types.typ": parse-number
#import "utils/palette.typ": default-discrete
#import "geom/point.typ" as point-geom
#import "geom/line.typ" as line-geom
#import "geom/col.typ" as col-geom
#import "geom/ribbon.typ" as ribbon-geom
#import "geom/smooth.typ" as smooth-geom
#import "geom/hline.typ" as hline-geom
#import "geom/vline.typ" as vline-geom
#import "geom/abline.typ" as abline-geom
#import "geom/text.typ" as text-geom
#import "geom/label.typ" as label-geom
#import "legend.typ" as legend-mod

// Flatten a merged aesthetic mapping so geoms receive plain column-name
// strings. Mapping-ref annotations produced by `as-factor("col")` have
// already been consumed by scale training by the time geoms draw.
#let _strip-mapping-refs(mapping) = {
  if mapping == none { return none }
  let out = mapping
  for (k, v) in mapping.pairs() {
    if v == none { continue }
    let col = mapping-ref-col(v)
    if col != v { out.insert(k, col) }
  }
  out
}

#let _merge-mapping(layer, plot-mapping) = {
  if layer.at("inherit-aes", default: true) and plot-mapping != none {
    let m = plot-mapping
    if layer.mapping != none {
      for (k, v) in layer.mapping.pairs() {
        if v != none { m.insert(k, v) }
      }
    }
    m
  } else if layer.mapping != none {
    layer.mapping
  } else {
    plot-mapping
  }
}

#let _resolve-mapping(layer, plot-mapping) = {
  _strip-mapping-refs(_merge-mapping(layer, plot-mapping))
}

#let _resolve-data(layer, plot-data) = {
  if layer.data != none { layer.data } else { plot-data }
}

#let _prepare-layer(layer, plot-mapping, plot-data) = {
  // Keep mapping-ref annotations intact on the layer so scale training can
  // read forced types; only strip them when the renderer hands a mapping to
  // a geom's draw function.
  let mapping = _merge-mapping(layer, plot-mapping)
  let data = _resolve-data(layer, plot-data)
  let stat-name = layer.at("stat", default: "identity")
  let params = layer.at("params", default: (:))
  let stripped = _strip-mapping-refs(mapping)

  let stat-identity = stat-name == none or stat-name == "identity"
  let stat-data = data
  let stat-mapping = if stat-identity { mapping } else { stripped }
  if not stat-identity {
    let r = apply-stat(stat-name, data, stripped, params)
    stat-data = r.data
    stat-mapping = r.mapping
  }

  let position-name = layer.at("position", default: "identity")
  let pos-data = stat-data
  let pos-mapping = stat-mapping
  if position-name != none and position-name != "identity" {
    // Position needs plain column names; strip again in case stat-identity
    // left annotations in place.
    let pos-in = _strip-mapping-refs(stat-mapping)
    let r = apply-position(position-name, stat-data, pos-in, params: params)
    pos-data = r.data
    // Merge position's additions (e.g. ymin/ymax) into the annotated mapping
    // while preserving existing annotations on x/y/...
    let merged = stat-mapping
    for (k, v) in r.mapping.pairs() {
      if merged.at(k, default: none) == none {
        merged.insert(k, v)
      }
    }
    pos-mapping = merged
  }

  let new = layer
  new.data = pos-data
  new.mapping = pos-mapping
  new.inherit-aes = false
  if not stat-identity { new.stat = "identity" }
  new
}

#let _scale-palette(trained, fallback) = {
  let spec = trained.at("spec", default: none)
  if spec == none { return fallback }
  let p = spec.at("palette", default: auto)
  if p == auto or p == none { fallback } else { p }
}

#let _resolve-colour(trained, value, palette) = {
  if trained == none or value == none or value == "" { return rgb("#222222") }
  let pal = _scale-palette(trained, palette)
  if trained.type == "discrete" {
    let s = str(value)
    let idx = trained.domain.position(v => v == s)
    if idx == none { return rgb("#222222") }
    pal.at(calc.rem(idx, pal.len()))
  } else {
    let v = if type(value) == str { float(value.trim()) } else { float(value) }
    let (d-lo, d-hi) = trained.domain
    if d-hi == d-lo { return pal.first() }
    let t = calc.max(0.0, calc.min(1.0, (v - d-lo) / (d-hi - d-lo)))
    let a = pal.first()
    let b = pal.last()
    a.mix((b, t * 100%))
  }
}

#let _format-break(n) = {
  if type(n) == int { return str(n) }
  if calc.abs(n - calc.round(n)) < 1e-9 { return str(calc.round(n)) }
  str(calc.round(n, digits: 3))
}

#let _extend-x-for-bins(trained, layers) = {
  if trained.at("x", default: none) == none { return trained }
  if trained.x.type != "continuous" { return trained }
  let max-half = 0.0
  for layer in layers {
    for row in layer.data {
      let w = row.at("width", default: none)
      if w != none and (type(w) == int or type(w) == float) {
        max-half = calc.max(max-half, w / 2)
      }
    }
  }
  if max-half == 0 { return trained }
  let (lo, hi) = trained.x.domain
  let new-x = trained.x
  new-x.insert("domain", (lo - max-half, hi + max-half))
  trained.insert("x", new-x)
  trained
}

#let _extend-y-for-ribbon(trained, layers) = {
  if trained.at("y", default: none) == none { return trained }
  if trained.y.type != "continuous" { return trained }
  let extras = ()
  for layer in layers {
    let mapping = layer.mapping
    if mapping == none { continue }
    for key in ("ymin", "ymax") {
      let col = mapping.at(key, default: none)
      if col == none { continue }
      for row in layer.data {
        let v = parse-number(row.at(col, default: none))
        if v != none { extras.push(v) }
      }
    }
  }
  if extras.len() == 0 { return trained }
  let (lo, hi) = trained.y.domain
  let new-lo = calc.min(lo, ..extras)
  let new-hi = calc.max(hi, ..extras)
  let new-y = trained.y
  new-y.insert("domain", (new-lo, new-hi))
  trained.insert("y", new-y)
  trained
}

#let _draw-axis-and-layers(
  prepared,
  trained,
  theme,
  spec,
  origin,
  inner-size,
  guides: (),
  legend-origin: none,
  legend-height: 0,
  show-x-labels: true,
  show-y-labels: true,
  show-x-title: true,
  show-y-title: true,
) = {
  import cetz.draw: *
  let (ox, oy) = origin
  let (iw, ih) = inner-size
  let px-lo = ox
  let px-hi = ox + iw
  let py-lo = oy
  let py-hi = oy + ih
  let px-range = (px-lo, px-hi)
  let py-range = (py-lo, py-hi)

  let ctx = (
    trained: trained,
    px-range: px-range,
    py-range: py-range,
    palette: default-discrete,
    resolve-mapping: layer => _resolve-mapping(layer, spec.mapping),
    resolve-data: layer => _resolve-data(layer, spec.data),
    resolve-colour: _resolve-colour,
  )

  if theme.panel-fill != none {
    rect(
      (px-lo, py-lo),
      (px-hi, py-hi),
      fill: theme.panel-fill,
      stroke: none,
    )
  }

  let x-trained = trained.at("x", default: none)
  let y-trained = trained.at("y", default: none)
  let grid-stroke = if theme.grid-colour == none { none } else {
    (paint: theme.grid-colour, thickness: theme.grid-thickness)
  }
  let axis-stroke = if theme.axis-colour == none { none } else {
    (paint: theme.axis-colour, thickness: theme.axis-thickness)
  }
  let tick-len = theme.tick-length

  if x-trained != none and x-trained.type == "continuous" {
    let breaks = pretty(x-trained.domain.at(0), x-trained.domain.at(1), n: 5)
    for b in breaks {
      let cx = map-continuous(b, x-trained.domain, px-range)
      if grid-stroke != none { line((cx, py-lo), (cx, py-hi), stroke: grid-stroke) }
      if axis-stroke != none and tick-len > 0 {
        line((cx, py-lo), (cx, py-lo - tick-len), stroke: axis-stroke)
      }
      if show-x-labels and theme.tick-labels {
        content(
          (cx, py-lo - 0.25),
          text(size: theme.axis-text-size)[#_format-break(b)],
          anchor: "north",
        )
      }
    }
  } else if x-trained != none and x-trained.type == "discrete" {
    let n = x-trained.domain.len()
    for (idx, level) in x-trained.domain.enumerate() {
      let cx = px-lo + (idx + 0.5) * (px-hi - px-lo) / n
      if axis-stroke != none and tick-len > 0 {
        line((cx, py-lo), (cx, py-lo - tick-len), stroke: axis-stroke)
      }
      if show-x-labels and theme.tick-labels {
        content(
          (cx, py-lo - 0.25),
          text(size: theme.axis-text-size)[#level],
          anchor: "north",
        )
      }
    }
  }

  if y-trained != none and y-trained.type == "continuous" {
    let breaks = pretty(y-trained.domain.at(0), y-trained.domain.at(1), n: 5)
    for b in breaks {
      let cy = map-continuous(b, y-trained.domain, py-range)
      if grid-stroke != none { line((px-lo, cy), (px-hi, cy), stroke: grid-stroke) }
      if axis-stroke != none and tick-len > 0 {
        line((px-lo - tick-len, cy), (px-lo, cy), stroke: axis-stroke)
      }
      if show-y-labels and theme.tick-labels {
        content(
          (px-lo - 0.2, cy),
          text(size: theme.axis-text-size)[#_format-break(b)],
          anchor: "east",
        )
      }
    }
  }

  if axis-stroke != none {
    line((px-lo, py-lo), (px-hi, py-lo), stroke: axis-stroke)
    line((px-lo, py-lo), (px-lo, py-hi), stroke: axis-stroke)
  }

  for layer in prepared {
    if layer.geom == "point" {
      point-geom.draw(layer, ctx)
    } else if layer.geom == "line" {
      line-geom.draw(layer, ctx)
    } else if layer.geom == "col" {
      col-geom.draw(layer, ctx)
    } else if layer.geom == "ribbon" {
      ribbon-geom.draw(layer, ctx)
    } else if layer.geom == "smooth" {
      smooth-geom.draw(layer, ctx)
    } else if layer.geom == "hline" {
      hline-geom.draw(layer, ctx)
    } else if layer.geom == "vline" {
      vline-geom.draw(layer, ctx)
    } else if layer.geom == "abline" {
      abline-geom.draw(layer, ctx)
    } else if layer.geom == "text" {
      text-geom.draw(layer, ctx)
    } else if layer.geom == "label" {
      label-geom.draw(layer, ctx)
    }
  }

  let x-title = {
    let from-scale = if x-trained != none and x-trained.spec != none { x-trained.spec.name } else { none }
    if from-scale != none { from-scale }
    else if spec.mapping != none { spec.mapping.at("x", default: none) }
    else { none }
  }
  let y-title = {
    let from-scale = if y-trained != none and y-trained.spec != none { y-trained.spec.name } else { none }
    if from-scale != none { from-scale }
    else if spec.mapping != none { spec.mapping.at("y", default: none) }
    else { none }
  }
  if show-x-title and x-title != none and theme.axis-title-size > 0pt {
    content(
      ((px-lo + px-hi) / 2, oy - 0.8),
      text(size: theme.axis-title-size, weight: "medium")[#x-title],
      anchor: "south",
    )
  }
  if show-y-title and y-title != none and theme.axis-title-size > 0pt {
    content(
      (px-lo - 1.1, (py-lo + py-hi) / 2),
      text(size: theme.axis-title-size, weight: "medium")[#y-title],
      angle: 90deg,
    )
  }

  if guides.len() > 0 and legend-origin != none {
    legend-mod.draw(guides, ctx, legend-origin, legend-height)
  }
}

// Inject labs `x`/`y`/... names into trained scale specs so axis and legend
// titles follow labs() just like ggplot2's labs() overrides.
#let _apply-labs(trained, labs) = {
  if labs == none { return trained }
  for (aes-name, label) in labs.axes.pairs() {
    if label == none { continue }
    let t = trained.at(aes-name, default: none)
    if t == none { continue }
    let spec = t.at("spec", default: none)
    let new-spec = if spec == none { (aesthetic: aes-name, name: label) } else {
      let s = spec
      s.insert("name", label)
      s
    }
    let new-t = t
    new-t.insert("spec", new-spec)
    trained.insert(aes-name, new-t)
  }
  trained
}

#let render-plot(spec) = {
  let prepared = spec.layers.map(l => _prepare-layer(l, spec.mapping, spec.data))
  let theme = merge-theme(spec.theme)
  let labs = spec.at("labs", default: none)

  let trained = train(
    scales: spec.scales,
    layers: prepared,
    mapping: spec.mapping,
    data: spec.data,
  )
  trained = _apply-labs(trained, labs)

  // Once training is done, mapping-ref annotations have served their purpose;
  // flatten them so geoms receive plain column names.
  prepared = prepared.map(l => {
    let new = l
    new.mapping = _strip-mapping-refs(l.mapping)
    new
  })

  // Bar-like geoms need the y domain to include zero.
  let has-bar = prepared.any(l => l.geom == "col")
  if has-bar and trained.at("y", default: none) != none and trained.y.type == "continuous" {
    let (lo, hi) = trained.y.domain
    let y-lo = calc.min(lo, 0.0)
    let y-hi = calc.max(hi, 0.0)
    let new-y = trained.y
    new-y.insert("domain", (y-lo, y-hi))
    trained.insert("y", new-y)
  }

  trained = _extend-x-for-bins(trained, prepared)
  trained = _extend-y-for-ribbon(trained, prepared)

  // coord-cartesian zooms the view: override trained domains with the user's
  // clip limits so axis ticks and marks follow them. Data outside still exists
  // for stats and training but may render outside the panel — ggplot's
  // "data is not dropped" distinction.
  let coord = spec.at("coord", default: none)
  if coord != none and coord.coord == "cartesian" {
    if coord.at("xlim", default: none) != none and trained.at("x", default: none) != none and trained.x.type == "continuous" {
      let new-x = trained.x
      new-x.insert("domain", coord.xlim)
      trained.insert("x", new-x)
    }
    if coord.at("ylim", default: none) != none and trained.at("y", default: none) != none and trained.y.type == "continuous" {
      let new-y = trained.y
      new-y.insert("domain", coord.ylim)
      trained.insert("y", new-y)
    }
  }

  let width-units = spec.width / 1cm
  let height-units = spec.height / 1cm

  let guides = legend-mod.guides-for(spec, trained)
  let legend-width = legend-mod.estimate-width(guides)
  let legend-gap = if legend-width > 0 { 0.25 } else { 0.0 }

  let margin = (left: 1.3, bottom: 0.9, top: 0.3, right: 0.3 + legend-gap + legend-width)

  let canvas = if spec.facet != none and spec.facet.facet == "wrap" {
    let levels = facet-wrap-mod.levels-for(prepared, spec.facet.var)
    let n = levels.len()
    let ncol = if spec.facet.ncol != none {
      spec.facet.ncol
    } else if spec.facet.nrow != none {
      calc.ceil(n / spec.facet.nrow)
    } else {
      calc.max(1, int(calc.ceil(calc.sqrt(n))))
    }
    let nrow = calc.max(1, int(calc.ceil(n / ncol)))
    let strip-h = 0.45
    let gutter-x = 0.4
    let gutter-y = 0.4
    let grid-w = width-units - margin.left - margin.right
    let grid-h = height-units - margin.bottom - margin.top
    let panel-w = (grid-w - gutter-x * (ncol - 1)) / ncol
    let panel-h = (grid-h - gutter-y * (nrow - 1) - strip-h * nrow) / nrow

    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      for (i, level) in levels.enumerate() {
        let col = calc.rem(i, ncol)
        let row = int(i / ncol)
        let x0 = margin.left + col * (panel-w + gutter-x)
        let y0 = margin.bottom + (nrow - 1 - row) * (panel-h + gutter-y + strip-h)
        rect(
          (x0, y0 + panel-h),
          (x0 + panel-w, y0 + panel-h + strip-h),
          fill: rgb("#e0e0e0"),
          stroke: none,
        )
        content(
          (x0 + panel-w / 2, y0 + panel-h + strip-h / 2),
          text(size: theme.axis-text-size, weight: "medium")[#level],
        )
        let filtered = facet-wrap-mod.filter-layers(prepared, spec.facet.var, level)
        _draw-axis-and-layers(
          filtered,
          trained,
          theme,
          spec,
          (x0, y0),
          (panel-w, panel-h),
          show-x-labels: row == nrow - 1,
          show-y-labels: col == 0,
          show-x-title: false,
          show-y-title: false,
        )
      }

      // Overall titles.
      let x-trained = trained.at("x", default: none)
      let y-trained = trained.at("y", default: none)
      let x-title = {
        let from-scale = if x-trained != none and x-trained.spec != none { x-trained.spec.name } else { none }
        if from-scale != none { from-scale }
        else if spec.mapping != none { spec.mapping.at("x", default: none) }
        else { none }
      }
      let y-title = {
        let from-scale = if y-trained != none and y-trained.spec != none { y-trained.spec.name } else { none }
        if from-scale != none { from-scale }
        else if spec.mapping != none { spec.mapping.at("y", default: none) }
        else { none }
      }
      if x-title != none and theme.axis-title-size > 0pt {
        content(
          (margin.left + grid-w / 2, 0.1),
          text(size: theme.axis-title-size, weight: "medium")[#x-title],
          anchor: "south",
        )
      }
      if y-title != none and theme.axis-title-size > 0pt {
        content(
          (0.2, margin.bottom + grid-h / 2),
          text(size: theme.axis-title-size, weight: "medium")[#y-title],
          angle: 90deg,
        )
      }

      if guides.len() > 0 {
        let ctx = (
          trained: trained,
          palette: default-discrete,
        )
        legend-mod.draw(
          guides,
          ctx,
          (margin.left + grid-w + legend-gap, margin.bottom),
          grid-h,
        )
      }
    })
  } else if spec.facet != none and spec.facet.facet == "grid" {
    let row-var = spec.facet.rows
    let col-var = spec.facet.cols
    let row-levels = if row-var == none { ("",) } else {
      facet-shared.levels-for(prepared, row-var)
    }
    let col-levels = if col-var == none { ("",) } else {
      facet-shared.levels-for(prepared, col-var)
    }
    let n-rows = calc.max(1, row-levels.len())
    let n-cols = calc.max(1, col-levels.len())
    let strip-h = 0.45
    let strip-w = 0.55
    let gutter-x = 0.3
    let gutter-y = 0.3
    let top-strip = if col-var != none { strip-h } else { 0.0 }
    let right-strip = if row-var != none { strip-w } else { 0.0 }
    let inner-right = margin.right + right-strip
    let grid-w = width-units - margin.left - inner-right
    let grid-h = height-units - margin.bottom - margin.top - top-strip
    let panel-w = (grid-w - gutter-x * (n-cols - 1)) / n-cols
    let panel-h = (grid-h - gutter-y * (n-rows - 1)) / n-rows

    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      for (r, row-lv) in row-levels.enumerate() {
        for (c, col-lv) in col-levels.enumerate() {
          let x0 = margin.left + c * (panel-w + gutter-x)
          let y0 = margin.bottom + (n-rows - 1 - r) * (panel-h + gutter-y)
          let filters = ()
          if row-var != none { filters.push((row-var, row-lv)) }
          if col-var != none { filters.push((col-var, col-lv)) }
          let filtered = facet-shared.filter-layers-multi(prepared, filters)
          _draw-axis-and-layers(
            filtered,
            trained,
            theme,
            spec,
            (x0, y0),
            (panel-w, panel-h),
            show-x-labels: r == n-rows - 1,
            show-y-labels: c == 0,
            show-x-title: false,
            show-y-title: false,
          )
        }
      }

      // Column strips on top.
      if col-var != none {
        let strip-y = margin.bottom + grid-h
        for (c, col-lv) in col-levels.enumerate() {
          let x0 = margin.left + c * (panel-w + gutter-x)
          rect(
            (x0, strip-y),
            (x0 + panel-w, strip-y + top-strip),
            fill: rgb("#e0e0e0"),
            stroke: none,
          )
          content(
            (x0 + panel-w / 2, strip-y + top-strip / 2),
            text(size: theme.axis-text-size, weight: "medium")[#col-lv],
          )
        }
      }

      // Row strips on the right.
      if row-var != none {
        let strip-x = margin.left + grid-w
        for (r, row-lv) in row-levels.enumerate() {
          let y0 = margin.bottom + (n-rows - 1 - r) * (panel-h + gutter-y)
          rect(
            (strip-x, y0),
            (strip-x + right-strip, y0 + panel-h),
            fill: rgb("#e0e0e0"),
            stroke: none,
          )
          content(
            (strip-x + right-strip / 2, y0 + panel-h / 2),
            text(size: theme.axis-text-size, weight: "medium")[#row-lv],
            angle: -90deg,
          )
        }
      }

      // Overall titles.
      let x-trained = trained.at("x", default: none)
      let y-trained = trained.at("y", default: none)
      let x-title = {
        let from-scale = if x-trained != none and x-trained.spec != none { x-trained.spec.name } else { none }
        if from-scale != none { from-scale }
        else if spec.mapping != none { spec.mapping.at("x", default: none) }
        else { none }
      }
      let y-title = {
        let from-scale = if y-trained != none and y-trained.spec != none { y-trained.spec.name } else { none }
        if from-scale != none { from-scale }
        else if spec.mapping != none { spec.mapping.at("y", default: none) }
        else { none }
      }
      if x-title != none and theme.axis-title-size > 0pt {
        content(
          (margin.left + grid-w / 2, 0.1),
          text(size: theme.axis-title-size, weight: "medium")[#x-title],
          anchor: "south",
        )
      }
      if y-title != none and theme.axis-title-size > 0pt {
        content(
          (0.2, margin.bottom + grid-h / 2),
          text(size: theme.axis-title-size, weight: "medium")[#y-title],
          angle: 90deg,
        )
      }

      if guides.len() > 0 {
        let ctx = (
          trained: trained,
          palette: default-discrete,
        )
        legend-mod.draw(
          guides,
          ctx,
          (margin.left + grid-w + right-strip + legend-gap, margin.bottom),
          grid-h,
        )
      }
    })
  } else {
    let px-lo = margin.left
    let px-hi = width-units - margin.right
    let py-lo = margin.bottom
    let py-hi = height-units - margin.top

    cetz.canvas(length: 1cm, {
      _draw-axis-and-layers(
        prepared,
        trained,
        theme,
        spec,
        (px-lo, py-lo),
        (px-hi - px-lo, py-hi - py-lo),
        guides: guides,
        legend-origin: (px-hi + legend-gap, py-lo),
        legend-height: py-hi - py-lo,
      )
    })
  }

  if labs == none { return canvas }
  let title-block = if labs.title != none {
    text(size: 12pt, weight: "bold")[#labs.title]
  } else { none }
  let subtitle-block = if labs.subtitle != none {
    text(size: 9pt, fill: rgb("#555555"))[#labs.subtitle]
  } else { none }
  let caption-block = if labs.caption != none {
    text(size: 8pt, fill: rgb("#555555"), style: "italic")[#labs.caption]
  } else { none }

  let parts = ()
  if title-block != none { parts.push(title-block) }
  if subtitle-block != none { parts.push(subtitle-block) }
  parts.push(canvas)
  if caption-block != none { parts.push(caption-block) }
  if parts.len() == 1 { return canvas }
  block(stack(dir: ttb, spacing: 0.3em, ..parts))
}
