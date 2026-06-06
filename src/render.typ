// CeTZ rendering glue.
// Draws a single cartesian panel with axes and layer marks.

#import "deps.typ": cetz
#import "scale/train.typ": mapping-display-name, positional-aesthetics, train
#import "scale/oob.typ": filter-oob
#import "theme/current.typ": _theme-state
#import "theme/defaults.typ": merge-theme, resolve-colour
#import "theme/theme.typ": (
  _rect-outset-cm, _rect-style, _scalar-cascade, _text-args, _text-style,
)
#import "utils/palette.typ": default-discrete
#import "utils/typst-markup.typ": resolve-prose
#import "utils/margin.typ": opposite-side, perpendicular-sides
#import "utils/label-draw.typ" as label-draw
#import "utils/measure.typ": measure-labels-cm, measure-text-cm
#import "utils/typst-markup.typ": eval-as-markup
#import "data.typ": group-by


#import "legend.typ" as legend-mod
#import "facet/labellers.typ" as labellers
#import "scale/secondary.typ" as secondary-mod
#import "render/common.typ": (
  _per-side, _resolve-data, _resolve-mapping, _should-draw-tick,
  _strip-mapping-refs, _track-min-max, _typst-marks-of,
)
#import "render/colour.typ": _make-resolve-colour
#import "render/axis-format.typ": (
  _axis-breaks, _axis-label, _axis-title, _format-temporal, _sec-spec,
  _shared-axis-breaks,
)
#import "render/guides.typ": (
  _THETA-CAP-FRAC, _THETA-CAP-MAX-RAD, _THETA-MINOR-TICK-FRAC, _axis-text-angle,
  _read-axis-guide, _read-theta-guide,
)
#import "render/prestat.typ": (
  _preprocess-data, _raw-levels-for, _rewrite-factor-cols,
)
#import "render/domain.typ": (
  _apply-coord, _apply-coord-transform, _apply-expand, _apply-flip, _apply-labs,
  _fixed-inner-size, _is-flipped, _post-train,
)
#import "render/extents.typ": (
  _AX-TITLE-LABEL-GAP, _X-LABEL-ROW-GAP, _Y-LABEL-COL-GAP, _ax-text-cm,
  _axis-guide-rows, _axis-label-extents, _resolve-extents, _sec-extent,
  _secondary-label-extents, _text-margin-cm, _x-label-depth,
  _x-label-depth-stack, _x-title-place, _y-label-width, _y-label-width-stack,
  _y-title-place,
)
#import "render/layer-prep.typ": _prepare-layer
#import "render/panel-draw.typ": _draw-axis-and-layers
// Re-exported so `compose.typ`'s `#import "render.typ": _decorate-*` resolves.
#import "render/decorate.typ": (
  _decorate-extents, _decorate-parts, _render-decorate,
)



#let _render-style(theme) = (
  strip-text: _text-style(theme, "strip-text"),
  ax-title: _per-side(
    (p, s, _) => _text-style(theme, p + "-" + s),
    "axis-title",
  ),
)

// Draw one facet strip: a filled rectangle with the labeller text centred
// inside. Shared between facet-wrap (top strip) and facet-grid (top + side
// strips). `angle` is `-90deg` for the rotated row-strip, else `0deg`. Text
// stays centred on the natural band so themed inset offsets paint past
// the band without dragging the label with them. `%` on inset resolves
// against the band's own dims (band-w x band-h) so a 5% inset paints
// inside the band rather than overflowing onto neighbouring panels.
#let _draw-strip(
  corner-lo,
  corner-hi,
  label-text,
  style,
  theme,
  angle: 0deg,
) = {
  let strip = _rect-style(
    theme,
    "strip-background",
    fallback-fill: theme.paper,
  )
  cetz.draw.rect(
    corner-lo,
    corner-hi,
    fill: strip.fill,
    stroke: strip.stroke,
  )
  let (cx, cy) = (
    (corner-lo.at(0) + corner-hi.at(0)) / 2,
    (corner-lo.at(1) + corner-hi.at(1)) / 2,
  )
  // Default centred. `left`/`right` slide the label to the matching end of
  // the band: along x for the top strip, along the reading direction (top
  // strip rotated, bottom is `right`) for the -90deg row strip.
  let a = style.strip-text.align
  let (sx, sy, s-anchor) = if angle == 0deg {
    if a == left {
      (corner-lo.at(0), cy, "west")
    } else if a == right {
      (corner-hi.at(0), cy, "east")
    } else { (cx, cy, "center") }
  } else {
    if a == left {
      (cx, corner-hi.at(1), "north")
    } else if a == right {
      (cx, corner-lo.at(1), "south")
    } else { (cx, cy, "center") }
  }
  cetz.draw.content(
    (sx, sy),
    text(.._text-args(style.strip-text))[#resolve-prose(
      label-text,
      eval-strings: style.strip-text.typst,
    )],
    angle: angle,
    anchor: s-anchor,
  )
}

// Resolve the strip text for every facet level once. The labeller text is
// needed both to size the strip band and (in facet-grid) to draw it, so it
// is computed up front rather than inside the cetz canvas closure, which
// cannot `measure` (the operation `_strip-band` relies on). `count-of` maps
// a level index to the row count fed to a context labeller.
#let _strip-texts(labeller, var, levels, count-of) = {
  levels
    .enumerate()
    .map(((i, lv)) => labellers.format(labeller, var, lv, count: count-of(i)))
}

// cm extent of a strip band sized to the tallest label, floored at `base`.
// A wrapped labeller (`label-wrap`) emits `\n`-joined lines, so the rendered
// height grows with the line count; `pad` keeps the same breathing room the
// old fixed constants gave a single line. For the rotated row-strip the
// measured height is the band's *width*, which is exactly what the caller
// wants.
#let _strip-band(labels, style, base) = {
  let prose = labels.map(l => resolve-prose(
    l,
    eval-strings: style.strip-text.typst,
  ))
  let pad = 0.16
  calc.max(base, measure-labels-cm(prose, style.strip-text.size).height + pad)
}


// ASCII Unit Separator joins the two grid-facet level strings into a single
// dict key. Assumed absent from any user-facing facet level.
#let _facet-key-sep = "\u{1F}"

// Build a (row-key-fn, panel-key-fn) pair for a grid facet spec, specialised
// on which of `rows` / `cols` is set. The row-key-fn is invoked once per data
// row inside `group-by` and must avoid per-row allocation. `none` values are
// coerced to "" so rows with missing facet variables drop out (panel levels
// from `_raw-levels-for` exclude `none`).
#let _facet-cell-str(row, col) = {
  let v = row.at(col, default: none)
  if v == none { "" } else { str(v) }
}

#let _grid-facet-keyers(spec) = {
  let r = spec.facet.rows
  let c = spec.facet.columns
  if r != none and c != none {
    return (
      row: row => (
        _facet-cell-str(row, r) + _facet-key-sep + _facet-cell-str(row, c)
      ),
      panel: (rl, cl) => rl + _facet-key-sep + cl,
    )
  }
  if r != none {
    return (
      row: row => _facet-cell-str(row, r),
      panel: (rl, _) => rl,
    )
  }
  (
    row: row => _facet-cell-str(row, c),
    panel: (_, cl) => cl,
  )
}

// Typst `measure()` is unreachable inside cetz canvas closures, so size each
// row's final label here and stash the result on the layer. The segment
// router consumes the sizes to clip connectors at the label edge and to
// detect crossings against sibling labels.
#let _measure-label-sizes(layer) = {
  let geom = layer.at("geom", default: none)
  if geom not in label-draw.LABEL-GEOMS { return layer }
  let params = layer.at("params", default: (:))
  if not (
    params.at("segment", default: false) or params.at("repel", default: false)
  ) { return layer }
  let mapping = layer.at("mapping", default: none)
  if mapping == none { return layer }
  let label-col = mapping.at("label", default: none)
  let const-label = params.at("label", default: none)
  let use-const = const-label != none
  if not use-const and label-col == none { return layer }
  let label-typst = (
    layer.at("typst-marks", default: (:)).at("label", default: false)
      or geom == "typst"
  )
  let size = params.at("size", default: 8pt)
  let inset = params.at("inset", default: 0pt)
  let inset-cm = if type(inset) == length { inset / 1cm } else { 0.0 }
  let sizes = layer
    .at("data", default: ())
    .map(row => {
      let label = if use-const { const-label } else {
        row.at(label-col, default: none)
      }
      if label == none { return (w: 0.0, h: 0.0) }
      if label-typst and type(label) == str { label = eval-as-markup(label) }
      let m = measure-text-cm(label, size)
      (w: m.width + 2 * inset-cm, h: m.height + 2 * inset-cm)
    })
  let new = layer
  new.insert("_label-sizes", sizes)
  new
}

#let _render-prepare(spec, theme) = {
  let facet-wrap-mode = spec.facet != none and spec.facet.facet == "wrap"
  let facet-grid-mode = spec.facet != none and spec.facet.facet == "grid"
  let coord = spec.at("coord", default: none)

  let wrap-levels = if facet-wrap-mode {
    _raw-levels-for(spec, spec.facet.variable)
  } else { () }

  let grid-row-levels = if facet-grid-mode and spec.facet.rows != none {
    _raw-levels-for(spec, spec.facet.rows)
  } else if facet-grid-mode { ("",) } else { () }
  let grid-col-levels = if facet-grid-mode and spec.facet.columns != none {
    _raw-levels-for(spec, spec.facet.columns)
  } else if facet-grid-mode { ("",) } else { () }

  // Partition each layer's data once by the facet key, then look up each
  // panel's subset in O(1).
  let panels = if facet-wrap-mode {
    let var = spec.facet.variable
    let layer-groups = spec.layers.map(l => group-by(
      _resolve-data(l, spec.data),
      row => _facet-cell-str(row, var),
    ))
    wrap-levels.map(level => (
      level: level,
      layers: spec
        .layers
        .enumerate()
        .map(((i, l)) => {
          let with-subset = l
          with-subset.data = layer-groups.at(i).at(level, default: ())
          with-subset.insert("data-trusted", true)
          _prepare-layer(
            with-subset,
            spec.mapping,
            spec.data,
            theme: theme,
            coord: coord,
          )
        }),
    ))
  } else if facet-grid-mode {
    let keyers = _grid-facet-keyers(spec)
    let layer-groups = spec.layers.map(l => group-by(
      _resolve-data(l, spec.data),
      keyers.row,
    ))
    let out = ()
    for row-lv in grid-row-levels {
      for col-lv in grid-col-levels {
        let key = (keyers.panel)(row-lv, col-lv)
        out.push((
          row-level: row-lv,
          col-level: col-lv,
          layers: spec
            .layers
            .enumerate()
            .map(((i, l)) => {
              let with-subset = l
              with-subset.data = layer-groups.at(i).at(key, default: ())
              with-subset.insert("data-trusted", true)
              _prepare-layer(
                with-subset,
                spec.mapping,
                spec.data,
                theme: theme,
                coord: coord,
              )
            }),
        ))
      }
    }
    out
  } else { () }

  let prepared = if facet-wrap-mode or facet-grid-mode {
    let union = ()
    for panel in panels { union += panel.layers }
    union
  } else {
    spec.layers.map(l => _prepare-layer(
      l,
      spec.mapping,
      spec.data,
      theme: theme,
      coord: coord,
    ))
  }

  (
    facet-wrap-mode: facet-wrap-mode,
    facet-grid-mode: facet-grid-mode,
    wrap-levels: wrap-levels,
    grid-row-levels: grid-row-levels,
    grid-col-levels: grid-col-levels,
    panels: panels,
    prepared: prepared,
  )
}

#let _panel-row-count(panel-layers) = {
  let n = 0
  for layer in panel-layers { n += layer.data.len() }
  n
}

#let _train-panels(spec, panels, trained, coord, labs, free-x, free-y) = {
  if not (free-x or free-y) { return () }
  // Only positional aesthetics are retrained per panel; non-positionals stay
  // shared so legends do not fragment. Labs labels must be re-applied because
  // pt.x / pt.y overwrite the globally-labelled merged.x / merged.y below.
  panels.map(p => {
    let pt = train(
      scales: spec.scales,
      layers: p.layers,
      mapping: spec.mapping,
      data: spec.data,
      aesthetics: positional-aesthetics,
    )
    pt = _apply-labs(pt, labs)
    pt = _post-train(pt, p.layers)
    pt = _apply-coord-transform(pt, coord)
    pt = _apply-coord(pt, coord)
    pt = _apply-expand(pt, coord)
    pt = _apply-flip(pt, coord)
    let merged = trained
    if free-x and pt.at("x", default: none) != none {
      merged.insert("x", pt.x)
    }
    if free-y and pt.at("y", default: none) != none {
      merged.insert("y", pt.y)
    }
    merged
  })
}

// Grid analogue of `_train-panels`: free-x trains x once PER COLUMN (union over
// the column's rows) and free-y trains y once PER ROW (union over the row's
// columns), so every panel in a column shares one x domain and every panel in a
// row shares one y domain (ggplot2 facet_grid semantics). Non-positional scales
// stay shared. Returns one merged trained dict per panel, indexed
// `r * n-cols + c`; `()` when neither axis is free.
#let _train-grid-panels(
  spec,
  panels,
  trained,
  coord,
  labs,
  n-rows,
  n-cols,
  free-x,
  free-y,
) = {
  if not (free-x or free-y) { return () }
  let n-layers = panels.at(0).layers.len()
  // Concatenate layer `li`'s data across a set of panel indices, preserving
  // layer order so `train` folds the group exactly like a single panel would.
  let union-layers = idxs => {
    range(n-layers).map(li => {
      let merged = panels.at(idxs.at(0)).layers.at(li)
      let data = ()
      for pi in idxs { data += panels.at(pi).layers.at(li).data }
      merged.data = data
      merged
    })
  }
  // Same positional pipeline as `_train-panels`, run once per group.
  let train-group = group-layers => {
    let pt = train(
      scales: spec.scales,
      layers: group-layers,
      mapping: spec.mapping,
      data: spec.data,
      aesthetics: positional-aesthetics,
    )
    pt = _apply-labs(pt, labs)
    pt = _post-train(pt, group-layers)
    pt = _apply-coord-transform(pt, coord)
    pt = _apply-coord(pt, coord)
    pt = _apply-expand(pt, coord)
    pt = _apply-flip(pt, coord)
    pt
  }
  // One trained x per column (union over its rows), one trained y per row.
  let col-x = if free-x {
    range(n-cols).map(c => {
      let idxs = range(n-rows).map(r => r * n-cols + c)
      train-group(union-layers(idxs)).at("x", default: none)
    })
  } else { none }
  let row-y = if free-y {
    range(n-rows).map(r => {
      let idxs = range(n-cols).map(c => r * n-cols + c)
      train-group(union-layers(idxs)).at("y", default: none)
    })
  } else { none }
  let out = ()
  for r in range(n-rows) {
    for c in range(n-cols) {
      let merged = trained
      if free-x and col-x.at(c) != none { merged.insert("x", col-x.at(c)) }
      if free-y and row-y.at(r) != none { merged.insert("y", row-y.at(r)) }
      out.push(merged)
    }
  }
  out
}

#let _render-canvas-wrap(ctx) = {
  let spec = ctx.spec
  let theme = ctx.theme
  let coord = ctx.coord
  let trained = ctx.trained
  let panels = ctx.panels
  let panel-trained-list = ctx.panel-trained-list
  let wrap-levels = ctx.wrap-levels
  let guides = ctx.guides
  let legend-gap = ctx.legend-gap
  let sec-y-extent = ctx.sec-y-extent
  let sec-x-extent = ctx.sec-x-extent
  let margin = ctx.margin
  let width-units = ctx.width-units
  let height-units = ctx.height-units
  let free-x = ctx.free-x
  let free-y = ctx.free-y
  let style = ctx.style
  let _ax-title = style.ax-title
  let x-extents = ctx.x-extents
  let y-extents = ctx.y-extents
  let x-sec-extents = ctx.x-sec-extents
  let y-sec-extents = ctx.y-sec-extents
  let ax-text = ctx.ax-text

  // Per-panel extents under free scales: each panel's trained scale carries
  // its own break/level set, so the longest label can differ panel-to-panel.
  // Measured here (still inside the outer `context`) before the canvas
  // closure, since cetz canvas does not expose layout measurement.
  let panel-extents = if not (free-x or free-y) {
    none
  } else {
    panel-trained-list.map(pt => {
      let xt = pt.at("x", default: none)
      let yt = pt.at("y", default: none)
      let xs = _sec-spec(xt)
      let ys = _sec-spec(yt)
      (
        x: if free-x {
          _axis-label-extents(xt, ax-text.xb.size, typst-eval: ax-text.xb.typst)
        } else { x-extents },
        y: if free-y {
          _axis-label-extents(yt, ax-text.yl.size, typst-eval: ax-text.yl.typst)
        } else { y-extents },
        x-sec: if free-x {
          _secondary-label-extents(
            xt,
            xs,
            ax-text.xt.size,
            typst-eval: ax-text.xt.typst,
          )
        } else { x-sec-extents },
        y-sec: if free-y {
          _secondary-label-extents(
            yt,
            ys,
            ax-text.yr.size,
            typst-eval: ax-text.yr.typst,
          )
        } else { y-sec-extents },
      )
    })
  }

  let levels = wrap-levels
  let n = levels.len()
  let ncol = if spec.facet.ncolumn != none {
    spec.facet.ncolumn
  } else if spec.facet.nrow != none {
    calc.ceil(n / spec.facet.nrow)
  } else {
    calc.max(1, int(calc.ceil(calc.sqrt(n))))
  }
  let nrow = calc.max(1, int(calc.ceil(n / ncol)))
  let strip-texts = _strip-texts(
    spec.facet.at("labeller", default: none),
    spec.facet.variable,
    levels,
    i => _panel-row-count(panels.at(i).layers),
  )
  let strip-h = _strip-band(strip-texts, style, 0.45)
  let gutter-x = 0.4
  let gutter-y = 0.4
  let grid-w = width-units - margin.left - margin.right
  let grid-h = height-units - margin.bottom - margin.top
  let panel-w = (grid-w - gutter-x * (ncol - 1)) / ncol
  let panel-h = (grid-h - gutter-y * (nrow - 1) - strip-h * nrow) / nrow

  // Compute shared breaks once per axis. A free axis sets its entry to
  // `none` so `_draw-axis-and-layers` falls back to per-panel computation
  // (the per-panel scale is what differs); the fixed axis still benefits
  // from the cached breaks even when the other axis is free.
  let shared-breaks = {
    let s = _shared-axis-breaks(trained)
    if free-x {
      s.insert("x", none)
      s.insert("x-sec", none)
    }
    if free-y {
      s.insert("y", none)
      s.insert("y-sec", none)
    }
    s
  }

  let all-x = ("all_x", "all").contains(spec.facet.axes)
  let all-y = ("all_y", "all").contains(spec.facet.axes)

  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    hide(rect((0, 0), (width-units, height-units)), bounds: true)
    for (i, level) in levels.enumerate() {
      let col = calc.rem(i, ncol)
      let row = int(i / ncol)
      let x0 = margin.left + col * (panel-w + gutter-x)
      let y0 = (
        margin.bottom + (nrow - 1 - row) * (panel-h + gutter-y + strip-h)
      )
      let panel-layers = panels.at(i).layers
      let strip-text = strip-texts.at(i)
      _draw-strip(
        (x0, y0 + panel-h),
        (x0 + panel-w, y0 + panel-h + strip-h),
        strip-text,
        style,
        theme,
      )
      let panel-trained = if panel-trained-list.len() == 0 {
        trained
      } else { panel-trained-list.at(i) }
      let (inner-w, inner-h) = _fixed-inner-size(
        coord,
        panel-trained,
        panel-w,
        panel-h,
      )
      let inner-y0 = y0 + (panel-h - inner-h)
      let _pe = if panel-extents != none {
        panel-extents.at(i)
      } else {
        (
          x: x-extents,
          y: y-extents,
          x-sec: x-sec-extents,
          y-sec: y-sec-extents,
        )
      }
      _draw-axis-and-layers(
        panel-layers,
        panel-trained,
        theme,
        spec,
        (x0, inner-y0),
        (inner-w, inner-h),
        // `i + ncol >= n`: no panel sits below this one, so it owns the
        // bottom x axis even if its row isn't the geometric last row
        // (trailing empty slots in a partial wrap).
        show-x-labels: free-x or all-x or i + ncol >= n,
        show-y-labels: free-y or all-y or col == 0,
        show-x-title: false,
        show-y-title: false,
        show-x-sec: free-x or all-x or row == 0,
        show-y-sec: free-y or all-y or col == ncol - 1,
        flipped: _is-flipped(coord),
        axis-breaks: shared-breaks,
        x-extents: _pe.x,
        y-extents: _pe.y,
        x-sec-extents: _pe.x-sec,
        y-sec-extents: _pe.y-sec,
        canvas-w: width-units,
        canvas-h: height-units,
      )
    }

    let x-trained = trained.at("x", default: none)
    let y-trained = trained.at("y", default: none)
    let _map-name(axis) = if spec.mapping == none { none } else {
      mapping-display-name(spec.mapping.at(axis, default: none))
    }
    let x-title = _axis-title(x-trained, _map-name("x"))
    let y-title = _axis-title(y-trained, _map-name("y"))
    let _len-side = (p, s, a) => _scalar-cascade(theme, p, s, a) / 1cm
    let _tick-len = _per-side(_len-side, "tick-length")
    let _xlbl-depth = _x-label-depth(0, 1, x-extents.width, x-extents.height)
    let _ylbl-width = _y-label-width(0, 1, y-extents.width, y-extents.height)
    let _xt-gap = _text-margin-cm(_ax-title.xb, "top", _AX-TITLE-LABEL-GAP)
    let _yt-gap = _text-margin-cm(_ax-title.yl, "right", _AX-TITLE-LABEL-GAP)
    let _xt-cm = _ax-text-cm(_ax-title.xb.size)
    let _yt-cm = _ax-text-cm(_ax-title.yl.size)
    if x-title != none and _ax-title.xb.size > 0pt {
      content(
        (
          margin.left + grid-w / 2,
          margin.bottom - _tick-len.xb - 0.1 - _xlbl-depth - _xt-gap - _xt-cm,
        ),
        text(.._text-args(_ax-title.xb))[#resolve-prose(
          x-title,
          eval-strings: _ax-title.xb.typst,
        )],
        anchor: "south",
      )
    }
    if y-title != none and _ax-title.yl.size > 0pt {
      content(
        (
          margin.left - _tick-len.yl - 0.1 - _ylbl-width - _yt-gap - _yt-cm / 2,
          margin.bottom + grid-h / 2,
        ),
        text(.._text-args(_ax-title.yl))[#resolve-prose(
          y-title,
          eval-strings: _ax-title.yl.typst,
        )],
        angle: 90deg,
      )
    }

    if guides.len() > 0 {
      let lctx = (
        trained: trained,
        palette: default-discrete,
        theme: theme,
        canvas-w: width-units,
        canvas-h: height-units,
      )
      legend-mod.draw(
        guides,
        lctx,
        panel-rect: (
          x: margin.left,
          y: margin.bottom,
          w: grid-w,
          h: grid-h,
        ),
        margin: margin,
        legend-gap: legend-gap,
        sec-y-extent: sec-y-extent,
        sec-x-extent: sec-x-extent,
        right-strip: 0.0,
        theme: theme,
      )
    }
  })
}

#let _render-canvas-grid(ctx) = {
  let spec = ctx.spec
  let theme = ctx.theme
  let coord = ctx.coord
  let trained = ctx.trained
  let panels = ctx.panels
  let grid-row-levels = ctx.grid-row-levels
  let grid-col-levels = ctx.grid-col-levels
  let guides = ctx.guides
  let legend-gap = ctx.legend-gap
  let sec-y-extent = ctx.sec-y-extent
  let sec-x-extent = ctx.sec-x-extent
  let margin = ctx.margin
  let width-units = ctx.width-units
  let height-units = ctx.height-units
  let style = ctx.style
  let _ax-title = style.ax-title
  let x-extents = ctx.x-extents
  let y-extents = ctx.y-extents
  let x-sec-extents = ctx.x-sec-extents
  let y-sec-extents = ctx.y-sec-extents
  let panel-trained-list = ctx.panel-trained-list
  let free-x = ctx.free-x
  let free-y = ctx.free-y

  let row-var = spec.facet.rows
  let col-var = spec.facet.columns
  let row-levels = grid-row-levels
  let col-levels = grid-col-levels
  let n-rows = calc.max(1, row-levels.len())
  let n-cols = calc.max(1, col-levels.len())
  let _grid-labeller = spec.facet.at("labeller", default: none)
  let _col-count(c) = {
    let n = 0
    for r in range(n-rows) {
      n += _panel-row-count(panels.at(r * n-cols + c).layers)
    }
    n
  }
  let _row-count(r) = {
    let n = 0
    for c in range(n-cols) {
      n += _panel-row-count(panels.at(r * n-cols + c).layers)
    }
    n
  }
  let col-strip-texts = if col-var == none { () } else {
    _strip-texts(_grid-labeller, col-var, col-levels, _col-count)
  }
  let row-strip-texts = if row-var == none { () } else {
    _strip-texts(_grid-labeller, row-var, row-levels, _row-count)
  }
  let strip-h = _strip-band(col-strip-texts, style, 0.45)
  let strip-w = _strip-band(row-strip-texts, style, 0.55)
  let gutter-x = 0.3
  let gutter-y = 0.3
  let top-strip = if col-var != none { strip-h } else { 0.0 }
  let right-strip = if row-var != none { strip-w } else { 0.0 }
  let inner-right = margin.right + right-strip
  let grid-w = width-units - margin.left - inner-right
  let grid-h = height-units - margin.bottom - margin.top - top-strip
  let panel-w = (grid-w - gutter-x * (n-cols - 1)) / n-cols
  let panel-h = (grid-h - gutter-y * (n-rows - 1)) / n-rows

  // Under free scales each column (x) / row (y) carries its own domain, so the
  // shared break set no longer applies; `none` makes `_draw-cartesian-axis`
  // recompute breaks from each panel's own trained scale.
  let shared-breaks = {
    let s = _shared-axis-breaks(trained)
    if free-x {
      s.insert("x", none)
      s.insert("x-sec", none)
    }
    if free-y {
      s.insert("y", none)
      s.insert("y-sec", none)
    }
    s
  }

  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    hide(rect((0, 0), (width-units, height-units)), bounds: true)
    for (r, row-lv) in row-levels.enumerate() {
      for (c, col-lv) in col-levels.enumerate() {
        let x0 = margin.left + c * (panel-w + gutter-x)
        let y0 = margin.bottom + (n-rows - 1 - r) * (panel-h + gutter-y)
        let panel-layers = panels.at(r * n-cols + c).layers
        let panel-trained = if panel-trained-list.len() == 0 {
          trained
        } else { panel-trained-list.at(r * n-cols + c) }
        let (inner-w, inner-h) = _fixed-inner-size(
          coord,
          panel-trained,
          panel-w,
          panel-h,
        )
        let inner-y0 = y0 + (panel-h - inner-h)
        _draw-axis-and-layers(
          panel-layers,
          panel-trained,
          theme,
          spec,
          (x0, inner-y0),
          (inner-w, inner-h),
          show-x-labels: r == n-rows - 1,
          show-y-labels: c == 0,
          show-x-title: false,
          show-y-title: false,
          show-x-sec: r == 0,
          show-y-sec: c == n-cols - 1,
          flipped: _is-flipped(coord),
          axis-breaks: shared-breaks,
          x-extents: x-extents,
          y-extents: y-extents,
          x-sec-extents: x-sec-extents,
          y-sec-extents: y-sec-extents,
          canvas-w: width-units,
          canvas-h: height-units,
        )
      }
    }

    if col-var != none {
      let strip-y = margin.bottom + grid-h
      for c in range(col-levels.len()) {
        let x0 = margin.left + c * (panel-w + gutter-x)
        _draw-strip(
          (x0, strip-y),
          (x0 + panel-w, strip-y + top-strip),
          col-strip-texts.at(c),
          style,
          theme,
        )
      }
    }

    if row-var != none {
      let strip-x = margin.left + grid-w
      for r in range(row-levels.len()) {
        let y0 = margin.bottom + (n-rows - 1 - r) * (panel-h + gutter-y)
        _draw-strip(
          (strip-x, y0),
          (strip-x + right-strip, y0 + panel-h),
          row-strip-texts.at(r),
          style,
          theme,
          angle: -90deg,
        )
      }
    }

    let x-trained = trained.at("x", default: none)
    let y-trained = trained.at("y", default: none)
    let _map-name(axis) = if spec.mapping == none { none } else {
      mapping-display-name(spec.mapping.at(axis, default: none))
    }
    let x-title = _axis-title(x-trained, _map-name("x"))
    let y-title = _axis-title(y-trained, _map-name("y"))
    let _len-side = (p, s, a) => _scalar-cascade(theme, p, s, a) / 1cm
    let _tick-len = _per-side(_len-side, "tick-length")
    let _xlbl-depth = _x-label-depth(0, 1, x-extents.width, x-extents.height)
    let _ylbl-width = _y-label-width(0, 1, y-extents.width, y-extents.height)
    let _xt-gap = _text-margin-cm(_ax-title.xb, "top", _AX-TITLE-LABEL-GAP)
    let _yt-gap = _text-margin-cm(_ax-title.yl, "right", _AX-TITLE-LABEL-GAP)
    let _xt-cm = _ax-text-cm(_ax-title.xb.size)
    let _yt-cm = _ax-text-cm(_ax-title.yl.size)
    if x-title != none and _ax-title.xb.size > 0pt {
      content(
        (
          margin.left + grid-w / 2,
          margin.bottom - _tick-len.xb - 0.1 - _xlbl-depth - _xt-gap - _xt-cm,
        ),
        text(.._text-args(_ax-title.xb))[#resolve-prose(
          x-title,
          eval-strings: _ax-title.xb.typst,
        )],
        anchor: "south",
      )
    }
    if y-title != none and _ax-title.yl.size > 0pt {
      content(
        (
          margin.left - _tick-len.yl - 0.1 - _ylbl-width - _yt-gap - _yt-cm / 2,
          margin.bottom + grid-h / 2,
        ),
        text(.._text-args(_ax-title.yl))[#resolve-prose(
          y-title,
          eval-strings: _ax-title.yl.typst,
        )],
        angle: 90deg,
      )
    }

    if guides.len() > 0 {
      let lctx = (
        trained: trained,
        palette: default-discrete,
        theme: theme,
        canvas-w: width-units,
        canvas-h: height-units,
      )
      legend-mod.draw(
        guides,
        lctx,
        panel-rect: (
          x: margin.left,
          y: margin.bottom,
          w: grid-w,
          h: grid-h,
        ),
        margin: margin,
        legend-gap: legend-gap,
        sec-y-extent: sec-y-extent,
        sec-x-extent: sec-x-extent,
        right-strip: right-strip,
        top-strip: top-strip,
        theme: theme,
      )
    }
  })
}

#let _render-canvas-single(
  spec,
  theme,
  trained,
  prepared,
  coord,
  guides,
  legend-gap,
  sec-y-extent,
  sec-x-extent,
  margin,
  width-units,
  height-units,
  x-extents,
  y-extents,
  x-sec-extents,
  y-sec-extents,
) = {
  let px-lo = margin.left
  let px-hi = width-units - margin.right
  let py-lo = margin.bottom
  let py-hi = height-units - margin.top

  let box-w = px-hi - px-lo
  let box-h = py-hi - py-lo
  let (inner-w, inner-h) = _fixed-inner-size(coord, trained, box-w, box-h)

  cetz.canvas(length: 1cm, {
    import cetz.draw: hide, rect
    hide(rect((0, 0), (width-units, height-units)), bounds: true)
    _draw-axis-and-layers(
      prepared,
      trained,
      theme,
      spec,
      (px-lo, py-lo),
      (inner-w, inner-h),
      guides: guides,
      legend-args: (
        panel-rect: (x: px-lo, y: py-lo, w: inner-w, h: inner-h),
        margin: margin,
        legend-gap: legend-gap,
        sec-y-extent: sec-y-extent,
        sec-x-extent: sec-x-extent,
        right-strip: 0.0,
      ),
      flipped: _is-flipped(coord),
      x-extents: x-extents,
      y-extents: y-extents,
      x-sec-extents: x-sec-extents,
      y-sec-extents: y-sec-extents,
      canvas-w: width-units,
      canvas-h: height-units,
    )
  })
}


#let render-plot-deferred(
  spec,
  suppress-aesthetics: (),
  margin-override: none,
) = {
  let user-theme = if spec.theme != none { spec.theme } else {
    _theme-state.get()
  }
  let theme = merge-theme(user-theme)
  let labs = spec.at("labs", default: none)

  // Canvas dims known up-front from `spec.width` / `spec.height`; cetz
  // draw sites resolve their own rect `%` insets against per-rect natural
  // dims, but layout-time `outset` reservation references the canvas.
  assert(
    type(spec.width) == length and type(spec.height) == length,
    message: "render-plot: width/height must be resolved to concrete lengths before rendering",
  )
  let width-units-early = spec.width / 1cm
  let height-units-early = spec.height / 1cm
  // `width` / `height` bound the whole image: build the title/subtitle/caption
  // chrome up front and reserve its extent so the canvas shrinks to leave room,
  // making the composed stack total back to the requested dims.
  let deco-parts = _decorate-parts(
    labs,
    theme,
    width-units-early,
    height-units-early,
  )
  let deco = _decorate-extents(deco-parts)
  let style = _render-style(theme)

  let spec = _preprocess-data(spec)

  // Faceted plots prepare layers per panel so stats (smooth, bin, count) fit
  // each panel's own row subset, following grammar-of-graphics semantics.
  let prep = _render-prepare(spec, theme)
  let facet-wrap-mode = prep.facet-wrap-mode
  let facet-grid-mode = prep.facet-grid-mode
  let wrap-levels = prep.wrap-levels
  let grid-row-levels = prep.grid-row-levels
  let grid-col-levels = prep.grid-col-levels
  let panels = prep.panels
  let prepared = prep.prepared

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
  panels = panels.map(p => {
    let new = p
    new.layers = p.layers.map(l => {
      let ll = l
      ll.mapping = _strip-mapping-refs(l.mapping)
      ll
    })
    new
  })

  // Faceted plots render the per-panel copies under `panels`; single plots
  // render `prepared` directly. Only the path that the canvas dispatch will
  // touch needs label sizes.
  if facet-wrap-mode or facet-grid-mode {
    panels = panels.map(p => {
      let new = p
      new.layers = p.layers.map(_measure-label-sizes)
      new
    })
  } else {
    prepared = prepared.map(_measure-label-sizes)
  }

  trained = _post-train(trained, prepared)

  // coord-cartesian zooms the view: override trained domains with the user's
  // clip limits so axis ticks and marks follow them. Data outside the limits
  // is preserved for stats and training but may render outside the panel.
  let coord = spec.at("coord", default: none)
  trained = _apply-coord-transform(trained, coord)
  trained = _apply-coord(trained, coord)
  trained = _apply-expand(trained, coord)
  // coord-flip swaps trained x and y so axis labels swap automatically;
  // direction-sensitive geoms branch on `ctx.flipped` inside their draw.
  trained = _apply-flip(trained, coord)

  // Drop (or clamp under `oob: "squish"`) rows whose value falls outside any
  // user-supplied scale `limits`. Runs after training so the trained domain
  // is the rendered cutoff; before per-panel re-train so panel scales see
  // the filtered subset.
  let strict = spec.at("strict", default: false)
  let oob-pass = filter-oob(prepared, trained, strict: strict)
  prepared = oob-pass.layers
  if facet-wrap-mode or facet-grid-mode {
    panels = panels.map(p => {
      let pass = filter-oob(p.layers, trained, strict: strict)
      let new = p
      new.layers = pass.layers
      new
    })
  }

  // For non-fixed facet scales, train each panel's positional axes on its own
  // subset so x and/or y differ across panels. Non-positional scales (colour,
  // fill, size, shape, linetype) stay shared so legends do not fragment.
  // facet-wrap frees each panel independently; facet-grid frees x per column
  // and y per row (see `_train-grid-panels`).
  let facet-scales = if facet-wrap-mode or facet-grid-mode {
    spec.facet.scales
  } else { "fixed" }
  let free-x = facet-scales == "free" or facet-scales == "free_x"
  let free-y = facet-scales == "free" or facet-scales == "free_y"
  let grid-n-rows = calc.max(1, grid-row-levels.len())
  let grid-n-cols = calc.max(1, grid-col-levels.len())
  let panel-trained-list = if facet-grid-mode {
    _train-grid-panels(
      spec,
      panels,
      trained,
      coord,
      labs,
      grid-n-rows,
      grid-n-cols,
      free-x,
      free-y,
    )
  } else {
    _train-panels(spec, panels, trained, coord, labs, free-x, free-y)
  }

  let width-units = width-units-early - deco.left - deco.right
  let height-units = height-units-early - deco.top - deco.bottom
  // Floor matches the single-tick panel minimum used by `max-right-margin`.
  let _min-canvas = 0.5
  if width-units < _min-canvas or height-units < _min-canvas {
    panic(
      "plot: title/subtitle/caption and plot-background padding leave a "
        + str(calc.round(width-units, digits: 2))
        + " x "
        + str(calc.round(height-units, digits: 2))
        + " cm canvas, below the "
        + str(_min-canvas)
        + " cm minimum; increase width/height or reduce labels/padding.",
    )
  }

  // Legend-text font size drives every label-width / line-height
  // measurement done inside `guides-for`.
  let _legend-size-pt = _text-style(theme, "legend-text").size / 1pt
  // Custom guides lack `aesthetics`; default keeps them unsuppressed.
  let guides = legend-mod
    .guides-for(spec, trained, size-pt: _legend-size-pt)
    .filter(g => {
      let aes = g.at("aesthetics", default: ())
      not aes.any(a => suppress-aesthetics.contains(a))
    })
  let extents = legend-mod.estimate-extents(guides)
  let any-legend = (
    extents.top > 0
      or extents.right > 0
      or extents.bottom > 0
      or extents.left > 0
      or extents.inside.len() > 0
  )
  let legend-title-style = _text-style(theme, "legend-title")
  let legend-gap = if any-legend {
    _text-margin-cm(legend-title-style, "left", 1.6em)
  } else { 0.0 }

  let x-trained-top = trained.at("x", default: none)
  let y-trained-top = trained.at("y", default: none)
  let x-sec = _sec-spec(x-trained-top)
  let y-sec = _sec-spec(y-trained-top)
  let _surface-style = (p, s, _) => _text-style(theme, p + "-" + s)
  let _len-side = (p, s, a) => _scalar-cascade(theme, p, s, a) / 1cm
  let tick-len = _per-side(_len-side, "tick-length")
  let ax-text = _per-side(_surface-style, "axis-text")
  let ax-title = _per-side(_surface-style, "axis-title")

  let x-extents = _axis-label-extents(
    x-trained-top,
    ax-text.xb.size,
    typst-eval: ax-text.xb.typst,
  )
  let y-extents = _axis-label-extents(
    y-trained-top,
    ax-text.yl.size,
    typst-eval: ax-text.yl.typst,
  )
  // Under facet-grid free scales the bottom row shows a different x per column
  // and the left column a different y per row, so the single bottom/left margin
  // must reserve the widest group's labels. Take the per-group maxima from the
  // panels that actually draw the edge axes (bottom row for x, left column for
  // y) using the same trained entries the draw will use.
  let x-extents = if (
    facet-grid-mode and free-x and panel-trained-list.len() > 0
  ) {
    let exts = range(grid-n-cols).map(c => _axis-label-extents(
      panel-trained-list
        .at((grid-n-rows - 1) * grid-n-cols + c)
        .at(
          "x",
          default: none,
        ),
      ax-text.xb.size,
      typst-eval: ax-text.xb.typst,
    ))
    (
      width: exts.fold(x-extents.width, (m, e) => calc.max(m, e.width)),
      height: exts.fold(x-extents.height, (m, e) => calc.max(m, e.height)),
    )
  } else { x-extents }
  let y-extents = if (
    facet-grid-mode and free-y and panel-trained-list.len() > 0
  ) {
    let exts = range(grid-n-rows).map(r => _axis-label-extents(
      panel-trained-list.at(r * grid-n-cols).at("y", default: none),
      ax-text.yl.size,
      typst-eval: ax-text.yl.typst,
    ))
    (
      width: exts.fold(y-extents.width, (m, e) => calc.max(m, e.width)),
      height: exts.fold(y-extents.height, (m, e) => calc.max(m, e.height)),
    )
  } else { y-extents }
  let x-sec-extents = _secondary-label-extents(
    x-trained-top,
    x-sec,
    ax-text.xt.size,
    typst-eval: ax-text.xt.typst,
  )
  let y-sec-extents = _secondary-label-extents(
    y-trained-top,
    y-sec,
    ax-text.yr.size,
    typst-eval: ax-text.yr.typst,
  )

  let sec-x-extent = _sec-extent(
    x-sec,
    tick-len.xt,
    x-sec-extents,
    ax-title.xt,
    "x",
  )
  let sec-y-extent = _sec-extent(
    y-sec,
    tick-len.yr,
    y-sec-extents,
    ax-title.yr,
    "y",
  )

  let x-guide = _read-axis-guide(
    spec,
    "x",
    default-angle: _axis-text-angle(theme, "x"),
  )
  let y-guide = _read-axis-guide(
    spec,
    "y",
    default-angle: _axis-text-angle(theme, "y"),
  )
  // Themes that disable tick labels (`theme-void`) reserve no perpendicular
  // depth for them; otherwise the chrome margin reserves space for ink that
  // never draws, inverting the panel rect on small plot sizes.
  let labels-on = theme.at("tick-labels", default: true)
  let x-label-depth = if labels-on {
    _x-label-depth-stack(x-guide, x-extents.width, x-extents.height)
  } else { 0.0 }
  let y-label-width = if labels-on {
    _y-label-width-stack(y-guide, y-extents.width, y-extents.height)
  } else { 0.0 }
  // A suppressed (`labs(x: none)`) or nameless axis title reserves no extent;
  // mirror the draw-side gate so the panel reclaims the freed depth.
  let _flipped = _is-flipped(coord)
  let _x-title-name = if spec.mapping == none { none } else {
    mapping-display-name(
      spec.mapping.at(if _flipped { "y" } else { "x" }, default: none),
    )
  }
  let _y-title-name = if spec.mapping == none { none } else {
    mapping-display-name(
      spec.mapping.at(if _flipped { "x" } else { "y" }, default: none),
    )
  }
  let x-title = _axis-title(trained.at("x", default: none), _x-title-name)
  let y-title = _axis-title(trained.at("y", default: none), _y-title-name)
  // Only reserve the title-to-label gap when a title actually renders;
  // a `0pt` axis title (e.g., `theme-void`) needs no gap, and the absolute
  // `_AX-TITLE-LABEL-GAP` would otherwise tip `bottom-extent` over the floor
  // threshold and invert the panel rect on short plots.
  let bottom-gap = if x-title != none and ax-title.xb.size > 0pt {
    _text-margin-cm(ax-title.xb, "top", _AX-TITLE-LABEL-GAP)
  } else { 0.0 }
  let left-gap = if y-title != none and ax-title.yl.size > 0pt {
    _text-margin-cm(ax-title.yl, "right", _AX-TITLE-LABEL-GAP)
  } else { 0.0 }
  let x-title-cm = if x-title != none { _ax-text-cm(ax-title.xb.size) } else {
    0.0
  }
  let y-title-cm = if y-title != none { _ax-text-cm(ax-title.yl.size) } else {
    0.0
  }
  let bottom-extent = (
    tick-len.xb + 0.1 + x-label-depth + bottom-gap + x-title-cm + 0.05
  )
  let left-extent = (
    tick-len.yl + 0.1 + y-label-width + left-gap + y-title-cm
  )

  // Cap the right margin so the legend can never push panel width below the
  // single-tick minimum. Without the cap, `px-hi - px-lo` goes negative and
  // axis labels render reversed (panel becomes mirror-imaged into the legend).
  let max-right-margin = calc.max(0.0, width-units - left-extent - 0.5)
  let _side-gap = side => (
    extents.at(side) + (if extents.at(side) > 0 { legend-gap } else { 0.0 })
  )
  // Themed `outset` on rect surfaces reserves outer whitespace by widening
  // the chrome slot on each side; the panel canvas absorbs the diff.
  // `strip-background` is the facet decoration band itself, so its `inset`
  // and `outset` are ignored (no chrome reservation, no rect growth).
  // For every legend on side S, all four `outset` sides feed chrome
  // reservation: slot-axis sides (S and its opposite) inflate `margin.S`
  // -- the opposite side (panel-facing) is also mirrored into
  // `legend-gap` so the visible gap between panel and legend grows;
  // perpendicular sides inflate the matching `margin.{perpendicular}`.
  let any-bar = guides.any(g => g.kind == "colourbar")
  let panel-out = _rect-outset-cm(
    theme,
    "panel-background",
    ref-w: width-units,
    ref-h: height-units,
  )
  let legend-out = _rect-outset-cm(
    theme,
    "legend-background",
    ref-w: width-units,
    ref-h: height-units,
  )
  let bar-out = if any-bar {
    _rect-outset-cm(
      theme,
      "legend-bar",
      ref-w: width-units,
      ref-h: height-units,
    )
  } else { (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0) }
  // For every active legend on side `leg-side`, the slot-axis outset
  // sides (leg-side + its opposite) sum into `margin.{leg-side}`; the
  // perpendicular sides feed `margin.{perpendicular}`. Fold once into a
  // four-side dict so `_surface-out` is a flat read.
  let _by-margin-side(out) = {
    let acc = (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0)
    for leg-side in ("top", "right", "bottom", "left") {
      if extents.at(leg-side) <= 0 { continue }
      acc.insert(
        leg-side,
        acc.at(leg-side)
          + out.at(leg-side)
          + out.at(opposite-side.at(leg-side)),
      )
      for perp in perpendicular-sides.at(leg-side) {
        acc.insert(perp, acc.at(perp) + out.at(perp))
      }
    }
    acc
  }
  let legend-by-side = _by-margin-side(legend-out)
  let bar-by-side = _by-margin-side(bar-out)
  let _surface-out(side) = (
    panel-out.at(side) + legend-by-side.at(side) + bar-by-side.at(side)
  )
  let margin = (
    left: left-extent + _side-gap("left") + _surface-out("left"),
    bottom: bottom-extent + _side-gap("bottom") + _surface-out("bottom"),
    top: sec-x-extent + _side-gap("top") + _surface-out("top"),
    right: calc.min(
      sec-y-extent + _side-gap("right") + _surface-out("right"),
      max-right-margin,
    ),
  )
  // `compose(align-panels: true)` forces a shared margin so panels' plot areas
  // line up; overlay the supplied sides, then clamp every side against this
  // panel's own extent so a forced margin can never invert the plot rect. Each
  // bound keeps at least 0.5cm of plot opposite it, matching `max-right-margin`.
  if margin-override != none {
    margin = margin + margin-override
    margin.right = calc.min(margin.right, max-right-margin)
    margin.left = calc.min(margin.left, calc.max(
      0.0,
      width-units - margin.right - 0.5,
    ))
    margin.top = calc.min(margin.top, calc.max(
      0.0,
      height-units - margin.bottom - 0.5,
    ))
    margin.bottom = calc.min(margin.bottom, calc.max(
      0.0,
      height-units - margin.top - 0.5,
    ))
  }

  let canvas = if facet-wrap-mode {
    _render-canvas-wrap((
      spec: spec,
      theme: theme,
      coord: coord,
      trained: trained,
      panels: panels,
      panel-trained-list: panel-trained-list,
      wrap-levels: wrap-levels,
      guides: guides,
      legend-gap: legend-gap,
      sec-y-extent: sec-y-extent,
      sec-x-extent: sec-x-extent,
      margin: margin,
      width-units: width-units,
      height-units: height-units,
      free-x: free-x,
      free-y: free-y,
      style: style,
      x-extents: x-extents,
      y-extents: y-extents,
      x-sec-extents: x-sec-extents,
      y-sec-extents: y-sec-extents,
      ax-text: ax-text,
    ))
  } else if facet-grid-mode {
    _render-canvas-grid((
      spec: spec,
      theme: theme,
      coord: coord,
      trained: trained,
      panels: panels,
      grid-row-levels: grid-row-levels,
      grid-col-levels: grid-col-levels,
      panel-trained-list: panel-trained-list,
      free-x: free-x,
      free-y: free-y,
      guides: guides,
      legend-gap: legend-gap,
      sec-y-extent: sec-y-extent,
      sec-x-extent: sec-x-extent,
      margin: margin,
      width-units: width-units,
      height-units: height-units,
      style: style,
      x-extents: x-extents,
      y-extents: y-extents,
      x-sec-extents: x-sec-extents,
      y-sec-extents: y-sec-extents,
    ))
  } else {
    _render-canvas-single(
      spec,
      theme,
      trained,
      prepared,
      coord,
      guides,
      legend-gap,
      sec-y-extent,
      sec-x-extent,
      margin,
      width-units,
      height-units,
      x-extents,
      y-extents,
      x-sec-extents,
      y-sec-extents,
    )
  }

  (
    content: _render-decorate(canvas, deco-parts),
    guides: guides,
    trained: trained,
    margin: margin,
  )
}

#let render-plot(spec) = render-plot-deferred(spec).content
