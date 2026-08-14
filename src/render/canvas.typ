// Canvas assembly: per-panel scale training for free scales and the three
// canvas builders (facet-wrap grid, facet-grid, single panel) that lay out
// panels, strips, shared axis titles, and the plot-level legend.

#import "../deps.typ": cetz
#import "../scale/train.typ": mapping-display-name, positional-aesthetics, train
#import "../theme/theme.typ": _text-args, _tick-length, resolve-theme-palette
#import "../utils/typst-markup.typ": resolve-prose
#import "../utils/gutter.typ": resolve-gutter
#import "legend.typ" as legend-mod
#import "common.typ": _per-side
#import "axis-format.typ": _axis-title, _sec-spec, _shared-axis-breaks
#import "domain.typ": (
  _apply-coord, _apply-coord-transform, _apply-expand, _apply-flip,
  _apply-labels, _fixed-inner-size, _is-flipped, _post-train,
)
#import "extents.typ": (
  _AX-TITLE-LABEL-GAP, _axis-label-extents, _sec-band-cm, _sec-title-offset-cm,
  _secondary-label-extents, _text-margin-cm, _title-angle, _title-body,
  _title-extent-cm, _x-title-place, _y-title-place,
)
#import "facet.typ": _draw-strip, _strip-band, _strip-texts
#import "panel-draw.typ": _draw-axis-and-layers

#let _panel-row-count(panel-layers) = {
  let n = 0
  for layer in panel-layers { n += layer.data.len() }
  n
}

// Per-panel positional retrain: train the positional aesthetics on a layer
// subset and run the same label/coord pipeline the top-level training gets,
// so a free panel scale behaves exactly like a shared one would.
#let _train-positional(spec, layers, coord, labels) = {
  let pt = train(
    scales: spec.scales,
    layers: layers,
    mapping: spec.mapping,
    data: spec.data,
    aesthetics: positional-aesthetics,
  )
  pt = _apply-labels(pt, labels)
  pt = _post-train(pt, layers)
  pt = _apply-coord-transform(pt, coord)
  pt = _apply-coord(pt, coord)
  pt = _apply-expand(pt, coord)
  _apply-flip(pt, coord)
}

// Shared break sets for a facet canvas. A free axis resets its entry to
// `none` so `_draw-cartesian-axis` falls back to per-panel computation (the
// per-panel scale is what differs); the fixed axis still benefits from the
// cached breaks even when the other axis is free.
#let _facet-shared-breaks(trained, free-x, free-y, coord: none) = {
  let s = _shared-axis-breaks(trained, coord: coord)
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

// Shared facet-canvas tail: the centred x/y axis titles plus the plot-level
// legend. Returns cetz elements; `grid-w`/`grid-h` are the panel-grid extents
// and `right-strip`/`top-strip` the facet-grid strip bands (0 under wrap).
#let _facet-titles-and-legend(
  ctx,
  grid-w,
  grid-h,
  right-strip: 0.0,
  top-strip: 0.0,
) = {
  let spec = ctx.spec
  let theme = ctx.theme
  let trained = ctx.trained
  let margin = ctx.margin
  let _ax-title = ctx.style.ax-title

  let x-trained = trained.at("x", default: none)
  let y-trained = trained.at("y", default: none)
  let _map-name(axis) = if spec.mapping == none { none } else {
    mapping-display-name(spec.mapping.at(axis, default: none))
  }
  let x-title = _axis-title(x-trained, _map-name("x"))
  let y-title = _axis-title(y-trained, _map-name("y"))
  let _len-side = (p, s, _) => _tick-length(theme, p + "-" + s) / 1cm
  let _tick-len = _per-side(_len-side, "axis-ticks")
  // The band between the panel grid and its title, and the gap that holds it
  // off the panel edge, are the ones `_chrome-margins` reserved, carried here
  // rather than recomputed: a suppressed axis draws no ticks or labels and a
  // radial panel draws neither band outside its edges, so recomputing them
  // means remembering both gates in a second place, and a title offset by a
  // band nothing drew lands outside its own margin, growing the canvas past
  // the requested size.
  let _xt-gap = _text-margin-cm(_ax-title.xb, "top", _AX-TITLE-LABEL-GAP)
  let _yt-gap = _text-margin-cm(_ax-title.yl, "right", _AX-TITLE-LABEL-GAP)
  let _xt-cm = _title-extent-cm(_ax-title.xb, ctx.x-title-extents, "x")
  let _yt-cm = _title-extent-cm(_ax-title.yl, ctx.y-title-extents, "y")
  // A shared title spans the whole grid, so the themed `align` pins it to the
  // grid's own ends, the way a single plot's pins it to the panel's.
  let _x-span = (margin.left, margin.left + grid-w)
  let _y-span = (margin.bottom, margin.bottom + grid-h)
  if x-title != none and _ax-title.xb.size > 0pt {
    let (cx, x-anchor) = _x-title-place(_ax-title.xb.align, .._x-span)
    cetz.draw.content(
      (
        cx,
        margin.bottom - ctx.x-label-band - ctx.x-band-gap - _xt-gap - _xt-cm,
      ),
      _title-body(x-title, _ax-title.xb, ctx.x-title-extents),
      anchor: x-anchor,
      angle: _title-angle(_ax-title.xb, 0),
    )
  }
  if y-title != none and _ax-title.yl.size > 0pt {
    let (cy, y-anchor) = _y-title-place(_ax-title.yl.align, .._y-span)
    cetz.draw.content(
      (
        margin.left - ctx.y-label-band - ctx.y-band-gap - _yt-gap - _yt-cm / 2,
        cy,
      ),
      _title-body(y-title, _ax-title.yl, ctx.y-title-extents),
      angle: _title-angle(_ax-title.yl, 90),
      anchor: y-anchor,
    )
  }

  // The secondary titles hang off the far edge of the grid rather than the
  // panel edge a single plot uses, so the strip bands sit between the axis and
  // its title. `_chrome-margins` reserved the same extent on that side, and the
  // extents carried here are the ones it fitted, so a long title arrives
  // already wrapped.
  let _x-sec = _sec-spec(x-trained, coord: ctx.coord)
  let _y-sec = _sec-spec(y-trained, coord: ctx.coord)
  if _x-sec != none and _x-sec.name != none and _ax-title.xt.size > 0pt {
    let _x-sec-offset = _sec-title-offset-cm(
      _tick-len.xt,
      ctx.x-sec-extents,
      _ax-title.xt,
      "x",
    )
    let (cx, x-anchor) = _x-title-place(_ax-title.xt.align, .._x-span)
    cetz.draw.content(
      (cx, margin.bottom + grid-h + top-strip + _x-sec-offset),
      _title-body(_x-sec.name, _ax-title.xt, ctx.x-sec-title-extents),
      anchor: x-anchor,
      angle: _title-angle(_ax-title.xt, 0),
    )
  }
  if _y-sec != none and _y-sec.name != none and _ax-title.yr.size > 0pt {
    let _y-sec-offset = _sec-title-offset-cm(
      _tick-len.yr,
      ctx.y-sec-extents,
      _ax-title.yr,
      "y",
    )
    let _y-sec-cm = _title-extent-cm(_ax-title.yr, ctx.y-sec-title-extents, "y")
    let (cy, y-anchor) = _y-title-place(_ax-title.yr.align, .._y-span)
    cetz.draw.content(
      (margin.left + grid-w + right-strip + _y-sec-offset + _y-sec-cm / 2, cy),
      _title-body(_y-sec.name, _ax-title.yr, ctx.y-sec-title-extents),
      angle: _title-angle(_ax-title.yr, 90),
      anchor: y-anchor,
    )
  }

  if ctx.guides.len() > 0 {
    let lctx = (
      trained: trained,
      palette: resolve-theme-palette(theme),
      theme: theme,
      canvas-w: ctx.width-units,
      canvas-h: ctx.height-units,
    )
    legend-mod.draw(
      ctx.guides,
      lctx,
      panel-rect: (
        x: margin.left,
        y: margin.bottom,
        w: grid-w,
        h: grid-h,
      ),
      margin: margin,
      legend-gap: ctx.legend-gap,
      sec-y-extent: ctx.sec-y-extent,
      sec-x-extent: ctx.sec-x-extent,
      right-strip: right-strip,
      top-strip: top-strip,
      theme: theme,
    )
  }
}

#let _train-panels(spec, panels, trained, coord, labels, free-x, free-y) = {
  if not (free-x or free-y) { return () }
  // Only positional aesthetics are retrained per panel; non-positionals stay
  // shared so legends do not fragment. Label names must be re-applied because
  // pt.x / pt.y overwrite the globally-labelled merged.x / merged.y below.
  panels.map(p => {
    let pt = _train-positional(spec, p.layers, coord, labels)
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
// row shares one y domain. Non-positional scales stay shared. Returns one merged
// trained dict per panel, indexed `r * n-cols + c`; `()` when neither axis is free.
#let _train-grid-panels(
  spec,
  panels,
  trained,
  coord,
  labels,
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
  let train-group = group-layers => _train-positional(
    spec,
    group-layers,
    coord,
    labels,
  )
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

// Resolve a facet's panel gutter to `(x:, y:)` cm floats: the facet's own
// `gutter:` argument wins, otherwise the theme `panel-spacing` (default 0.5cm).
#let _facet-gutter(facet, theme, scope) = resolve-gutter(
  if facet.at("gutter", default: auto) == auto {
    theme.at("panel-spacing", default: 0.5cm)
  } else { facet.gutter },
  scope: scope,
)

// Depth (cm) a facet cell owes the secondary axis on `axis`: zero unless the
// trained scale carries a `secondary:` spec that the panels actually draw.
// Under free scales each panel measures its own labels, so the widest wins
// and every cell keeps the same geometry.
#let _facet-sec-band(ctx, panel-extents, axis) = {
  let trained = ctx.trained.at(axis, default: none)
  if _sec-spec(trained, coord: ctx.coord) == none { return 0.0 }
  let style = if axis == "x" { ctx.ax-text.xt } else { ctx.ax-text.yr }
  if style.size <= 0pt { return 0.0 }
  let key = axis + "-sec"
  let base = if axis == "x" { ctx.x-sec-extents } else { ctx.y-sec-extents }
  let ext = if panel-extents == none { base } else {
    panel-extents.fold(base, (m, pe) => {
      let e = pe.at(key, default: base)
      (
        width: calc.max(m.width, e.width),
        height: calc.max(m.height, e.height),
      )
    })
  }
  let side = if axis == "x" { "axis-ticks-xt" } else { "axis-ticks-yr" }
  _sec-band-cm(_tick-length(ctx.theme, side) / 1cm, ext, axis)
}

#let _render-canvas-wrap(ctx) = {
  let spec = ctx.spec
  let theme = ctx.theme
  let coord = ctx.coord
  let trained = ctx.trained
  let panels = ctx.panels
  let panel-trained-list = ctx.panel-trained-list
  let wrap-levels = ctx.wrap-levels
  let margin = ctx.margin
  let width-units = ctx.width-units
  let height-units = ctx.height-units
  let free-x = ctx.free-x
  let free-y = ctx.free-y
  let style = ctx.style
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
      let xs = _sec-spec(xt, coord: coord)
      let ys = _sec-spec(yt, coord: coord)
      (
        x: if free-x {
          _axis-label-extents(
            xt,
            ax-text.xb.size,
            "x",
            coord,
            typst-eval: ax-text.xb.typst,
          )
        } else { x-extents },
        y: if free-y {
          _axis-label-extents(
            yt,
            ax-text.yl.size,
            "y",
            coord,
            typst-eval: ax-text.yl.typst,
          )
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
  let gutters = _facet-gutter(spec.facet, theme, "facet-wrap")
  let gutter-x = gutters.x
  let gutter-y = gutters.y

  let all-x = ("all_x", "all").contains(spec.facet.axes)
  let all-y = ("all_y", "all").contains(spec.facet.axes)

  // A panel's secondary x axis is drawn at its top edge, which is exactly
  // where the strip band above it is painted, so the cell reserves the axis
  // depth between the two. Only the rows that draw one pay for it: with fixed
  // scales that is the top row alone, and every panel keeps the same size
  // either way because the band is inserted inside the cell.
  let sec-band = _facet-sec-band(ctx, panel-extents, "x")
  let rows-with-sec = if sec-band <= 0 { 0 } else if free-x or all-x {
    nrow
  } else { 1 }
  let _sec-band-of = row => if sec-band > 0 and (free-x or all-x or row == 0) {
    sec-band
  } else { 0.0 }

  let grid-w = width-units - margin.left - margin.right
  let grid-h = height-units - margin.bottom - margin.top
  // Gutters and strips are fixed costs the grid pays before the panels get
  // anything, so a small enough plot leaves each panel nothing. Floor at zero:
  // an empty panel is honest, a negative one draws mirrored.
  let panel-w = calc.max(0.0, (grid-w - gutter-x * (ncol - 1)) / ncol)
  let panel-h = calc.max(
    0.0,
    (
      (
        grid-h
          - gutter-y * (nrow - 1)
          - strip-h * nrow
          - sec-band * rows-with-sec
      )
        / nrow
    ),
  )

  let shared-breaks = _facet-shared-breaks(
    trained,
    free-x,
    free-y,
    coord: coord,
  )

  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    hide(rect((0, 0), (width-units, height-units)), bounds: true)
    for (i, level) in levels.enumerate() {
      let col = calc.rem(i, ncol)
      let row = int(i / ncol)
      let x0 = margin.left + col * (panel-w + gutter-x)
      // Rows below this one each contribute a cell plus a gutter, and a cell
      // is the panel, its own secondary band, and its strip.
      let y0 = (
        margin.bottom
          + range(row + 1, nrow).fold(
            0.0,
            (acc, r) => acc + panel-h + _sec-band-of(r) + strip-h + gutter-y,
          )
      )
      let panel-layers = panels.at(i).layers
      let strip-text = strip-texts.at(i)
      let strip-y = y0 + panel-h + _sec-band-of(row)
      _draw-strip(
        (x0, strip-y),
        (x0 + panel-w, strip-y + strip-h),
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
        show-x-sec-title: false,
        show-y-sec-title: false,
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

    _facet-titles-and-legend(ctx, grid-w, grid-h)
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
  let margin = ctx.margin
  let width-units = ctx.width-units
  let height-units = ctx.height-units
  let style = ctx.style
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
  let gutters = _facet-gutter(spec.facet, theme, "facet-grid")
  let gutter-x = gutters.x
  let gutter-y = gutters.y
  let top-strip = if col-var != none { strip-h } else { 0.0 }
  let right-strip = if row-var != none { strip-w } else { 0.0 }
  // The top row draws its secondary x axis at the grid's top edge, under the
  // column strips, which are painted after every panel and would cover it.
  // Reserve the axis depth between the two. The right column's secondary y
  // does the same against the row strips.
  let sec-band-x = if col-var == none { 0.0 } else {
    _facet-sec-band(ctx, none, "x")
  }
  let sec-band-y = if row-var == none { 0.0 } else {
    _facet-sec-band(ctx, none, "y")
  }
  let inner-right = margin.right + right-strip + sec-band-y
  let grid-w = width-units - margin.left - inner-right
  let grid-h = (
    height-units - margin.bottom - margin.top - top-strip - sec-band-x
  )
  // Floored at zero for the same reason as the wrap builder above.
  let panel-w = calc.max(0.0, (grid-w - gutter-x * (n-cols - 1)) / n-cols)
  let panel-h = calc.max(0.0, (grid-h - gutter-y * (n-rows - 1)) / n-rows)

  let shared-breaks = _facet-shared-breaks(
    trained,
    free-x,
    free-y,
    coord: coord,
  )

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
          show-x-sec-title: false,
          show-y-sec-title: false,
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
      let strip-y = margin.bottom + grid-h + sec-band-x
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
      let strip-x = margin.left + grid-w + sec-band-y
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

    _facet-titles-and-legend(
      ctx,
      grid-w,
      grid-h,
      right-strip: right-strip + sec-band-y,
      top-strip: top-strip + sec-band-x,
    )
  })
}

// Single-panel canvas builder; takes the same named-dict ctx convention as
// `_render-canvas-wrap` / `_render-canvas-grid`.
#let _render-canvas-single(ctx) = {
  let coord = ctx.coord
  let trained = ctx.trained
  let margin = ctx.margin
  let width-units = ctx.width-units
  let height-units = ctx.height-units

  let px-lo = margin.left
  let px-hi = width-units - margin.right
  let py-lo = margin.bottom
  let py-hi = height-units - margin.top

  // Chrome can consume the whole canvas on a very small plot; floor the panel at
  // zero so it draws empty rather than inverting into a mirrored rect.
  let box-w = calc.max(0.0, px-hi - px-lo)
  let box-h = calc.max(0.0, py-hi - py-lo)
  let (inner-w, inner-h) = _fixed-inner-size(coord, trained, box-w, box-h)

  cetz.canvas(length: 1cm, {
    import cetz.draw: hide, rect
    hide(rect((0, 0), (width-units, height-units)), bounds: true)
    _draw-axis-and-layers(
      ctx.prepared,
      trained,
      ctx.theme,
      ctx.spec,
      (px-lo, py-lo),
      (inner-w, inner-h),
      guides: ctx.guides,
      legend-args: (
        panel-rect: (x: px-lo, y: py-lo, w: inner-w, h: inner-h),
        margin: margin,
        legend-gap: ctx.legend-gap,
        sec-y-extent: ctx.sec-y-extent,
        sec-x-extent: ctx.sec-x-extent,
        right-strip: 0.0,
      ),
      flipped: _is-flipped(coord),
      x-extents: ctx.x-extents,
      y-extents: ctx.y-extents,
      x-title-extents: ctx.x-title-extents,
      y-title-extents: ctx.y-title-extents,
      x-sec-title-extents: ctx.x-sec-title-extents,
      y-sec-title-extents: ctx.y-sec-title-extents,
      x-sec-extents: ctx.x-sec-extents,
      y-sec-extents: ctx.y-sec-extents,
      canvas-w: width-units,
      canvas-h: height-units,
    )
  })
}
