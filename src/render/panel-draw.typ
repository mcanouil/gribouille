// Panel renderer: the geom-dispatch table and `_draw-axis-and-layers`, which
// draws one panel's background, gridlines, axes (cartesian + radial), geom
// marks, axis titles, and any panel-local legend.

#import "../deps.typ": cetz
#import "../utils/errors.typ": fail
#import "../scale/train.typ": (
  map-axis-data, map-break, mapping-display-name, transform-inv,
)
#import "../theme/defaults.typ": resolve-colour
#import "../theme/theme.typ": (
  _line-stroke, _rect-style, _text-args, _text-style, _tick-length,
  resolve-theme-palette,
)
#import "../utils/radial.typ": radial-ctx, theta-axis-of
#import "../utils/typst-markup.typ": resolve-prose
#import "../utils/aes-resolve.typ": resolve-label
#import "../utils/format.typ": format-break
#import "../utils/palette.typ": spec-attr
#import "../scale/secondary.typ" as secondary-mod
#import "legend.typ" as legend-mod
#import "common.typ": (
  _per-side, _resolve-data, _resolve-mapping, _should-draw-tick,
)
#import "colour.typ": _make-resolve-colour
#import "panel-radial.typ": _draw-radial-panel, _draw-radial-r-labels
#import "axis-format.typ": (
  _axis-breaks, _axis-minor-breaks, _axis-tick-values, _axis-title,
  _log10-minor-positions, _sec-spec, _secondary-breaks, _tick-label-fallback,
)
#import "guides.typ": _axis-text-angle, _read-axis-guide, _read-theta-guide
#import "extents.typ": (
  _AX-TITLE-LABEL-GAP, _TICK-LABEL-GAP, _X-LABEL-ROW-GAP, _Y-LABEL-COL-GAP,
  _axis-guide-rows, _resolve-extents, _sec-title-offset-cm, _text-margin-cm,
  _theta-label-bounds, _title-angle, _title-body, _title-extent-cm,
  _x-label-anchor, _x-title-place, _y-title-place,
)

#import "../geom/point.typ" as point-geom
#import "../geom/line.typ" as line-geom
#import "../geom/path.typ" as path-geom
#import "../geom/step.typ" as step-geom
#import "../geom/area.typ" as area-geom
#import "../geom/rect.typ" as rect-geom
#import "../geom/tile.typ" as tile-geom
#import "../geom/segment.typ" as segment-geom
#import "../geom/curve.typ" as curve-geom
#import "../geom/spoke.typ" as spoke-geom
#import "../geom/polygon.typ" as polygon-geom
#import "../geom/ellipse.typ" as ellipse-geom
#import "../geom/mark.typ" as mark-geom
#import "../geom/col.typ" as col-geom
#import "../geom/ribbon.typ" as ribbon-geom
#import "../geom/smooth.typ" as smooth-geom
#import "../geom/hline.typ" as hline-geom
#import "../geom/vline.typ" as vline-geom
#import "../geom/abline.typ" as abline-geom
#import "../geom/text.typ" as text-geom
#import "../geom/typst.typ" as typst-geom
#import "../geom/label.typ" as label-geom
#import "../geom/boxplot.typ" as boxplot-geom
#import "../geom/violin.typ" as violin-geom
#import "../geom/density-ridges.typ" as density-ridges-geom
#import "../geom/errorbar.typ" as errorbar-geom
#import "../geom/errorbarh.typ" as errorbarh-geom
#import "../geom/linerange.typ" as linerange-geom
#import "../geom/crossbar.typ" as crossbar-geom
#import "../geom/pointrange.typ" as pointrange-geom
#import "../geom/blank.typ" as blank-geom
#import "../geom/rug.typ" as rug-geom
#import "../geom/function.typ" as function-geom
#import "../geom/dotplot.typ" as dotplot-geom
#import "../geom/hex.typ" as hex-geom

// Single source of truth for layer dispatch in `_draw-axis-and-layers`.
// Each entry maps a layer's `geom` string to its `draw(layer, ctx)` function.
// Adding a new geom only requires importing it above and adding an entry here.
#let _geom-draw = (
  point: point-geom.draw,
  line: line-geom.draw,
  path: path-geom.draw,
  step: step-geom.draw,
  area: area-geom.draw,
  rect: rect-geom.draw,
  tile: tile-geom.draw,
  segment: segment-geom.draw,
  curve: curve-geom.draw,
  spoke: spoke-geom.draw,
  polygon: polygon-geom.draw,
  ellipse: ellipse-geom.draw,
  mark: mark-geom.draw,
  col: col-geom.draw,
  ribbon: ribbon-geom.draw,
  smooth: smooth-geom.draw,
  hline: hline-geom.draw,
  vline: vline-geom.draw,
  abline: abline-geom.draw,
  text: text-geom.draw,
  typst: typst-geom.draw,
  label: label-geom.draw,
  boxplot: boxplot-geom.draw,
  violin: violin-geom.draw,
  "density-ridges": density-ridges-geom.draw,
  errorbar: errorbar-geom.draw,
  errorbarh: errorbarh-geom.draw,
  linerange: linerange-geom.draw,
  crossbar: crossbar-geom.draw,
  pointrange: pointrange-geom.draw,
  blank: blank-geom.draw,
  rug: rug-geom.draw,
  function: function-geom.draw,
  dotplot: dotplot-geom.draw,
  hex: hex-geom.draw,
)

// Layers whose `geom` is missing from this set panic under `coord-radial`
// rather than silently falling back to cartesian rendering. Every registered
// geom is currently radial-aware; the check below guards against typos and
// future geoms that intentionally opt out. Stored as a dict-set so per-layer
// membership tests are O(1) instead of an array scan.
#let _RADIAL-AWARE = {
  let s = (:)
  for k in _geom-draw.keys() { s.insert(k, true) }
  s
}

#let _draw-axis-and-layers(
  prepared,
  trained,
  theme,
  spec,
  origin,
  inner-size,
  guides: (),
  legend-args: none,
  show-x-labels: true,
  show-y-labels: true,
  show-x-title: true,
  show-y-title: true,
  show-x-sec: true,
  show-y-sec: true,
  // Facet builders draw one secondary title for the whole grid, the way they
  // already do for the primary pair, so their panels keep the secondary ticks
  // and labels but drop the title.
  show-x-sec-title: true,
  show-y-sec-title: true,
  flipped: false,
  axis-breaks: none,
  x-extents: none,
  y-extents: none,
  x-title-extents: none,
  y-title-extents: none,
  x-sec-title-extents: none,
  y-sec-title-extents: none,
  x-sec-extents: none,
  y-sec-extents: none,
  // Band between the panel edge and its axis title, gap included, as
  // `_chrome-margins` reserved it. Carried rather than recomputed so the title
  // cannot land outside its own margin. The facet builders draw one title for
  // the whole grid and pass `show-x-title: false`, so these go unread there.
  x-edge-band: 0.0,
  y-edge-band: 0.0,
  canvas-w: 0,
  canvas-h: 0,
) = {
  import cetz.draw: *
  let (ox, oy) = origin
  let (iw, ih) = inner-size
  let px-lo = ox
  let px-hi = ox + iw
  let py-lo = oy
  let py-hi = oy + ih
  // `px-range`/`py-range` carry the inset *data area* (panel bounds shrunk by
  // any canvas-cm padding from `view-pad-cm`), so geoms and ticks land on the
  // correct data positions. Bare `px-lo`/`py-lo`/`px-hi`/`py-hi` keep the
  // outer panel bounds and are used for axis lines, panel fill, and gridline
  // endpoints that span the full panel.
  let _read-pad(t) = if t == none { (0, 0) } else {
    t.at("view-pad-cm", default: (0, 0))
  }
  let (x-pad-lo, x-pad-hi) = _read-pad(trained.at("x", default: none))
  let (y-pad-lo, y-pad-hi) = _read-pad(trained.at("y", default: none))
  let px-range = (px-lo + x-pad-lo, px-hi - x-pad-hi)
  let py-range = (py-lo + y-pad-lo, py-hi - y-pad-hi)

  let _ink = resolve-colour(theme, "ink")
  let _surface-style = (p, s, _) => _text-style(theme, p + "-" + s)
  let _ax-text = _per-side(_surface-style, "axis-text")
  let _ax-title = _per-side(_surface-style, "axis-title")

  let _resolve-mapping-flipped(layer) = {
    let m = _resolve-mapping(layer, spec.mapping)
    if not flipped or m == none { return m }
    let x = m.at("x", default: none)
    let y = m.at("y", default: none)
    let out = m
    out.insert("x", y)
    out.insert("y", x)
    out
  }

  // Canonical per-draw context handed to every geom's `draw(layer, ctx)`
  // (GLOSSARY.md "ctx"): `trained`, `px-range`/`py-range` (panel extents in
  // canvas cm), `palette`, the `resolve-mapping`/`resolve-data`/
  // `resolve-colour` closures, `theme`, `flipped`, `canvas-w`/`canvas-h`.
  // The geom-dispatch copy (`inner-ctx`, below) additionally carries
  // `radial` (`none` on cartesian panels); read optional keys with
  // `ctx.at(key, default: ...)`.
  let ctx = (
    trained: trained,
    px-range: px-range,
    py-range: py-range,
    palette: resolve-theme-palette(theme),
    resolve-mapping: layer => _resolve-mapping-flipped(layer),
    resolve-data: layer => _resolve-data(layer, spec.data),
    resolve-colour: _make-resolve-colour(_ink),
    theme: theme,
    flipped: flipped,
    canvas-w: canvas-w,
    canvas-h: canvas-h,
  )

  let x-trained = trained.at("x", default: none)
  let y-trained = trained.at("y", default: none)

  let coord = spec.at("coord", default: none)
  // The theta tick labels ring the circle just outside it, so the circle has
  // to leave them room inside the panel: the panel is all the room the chrome
  // granted, and a label past its edge grows the whole figure past the
  // requested `width`/`height`. Gate the band on the same conditions the draw
  // does, so a suppressed or blank theta axis gives it back.
  let _theta-guide = _read-theta-guide(spec)
  let _theta-key = theta-axis-of(coord)
  let _label-bounds = if _theta-key == none { () } else {
    let _theta-text = if _theta-key == "x" { _ax-text.xb } else { _ax-text.yl }
    if (
      _theta-text.size > 0pt
        and not (_theta-guide != none and _theta-guide.suppress)
    ) {
      _theta-label-bounds(
        _resolve-extents(
          if _theta-key == "x" { x-extents } else { y-extents },
          _theta-text.size,
        ).at("groups", default: ()),
        if _theta-guide == none { 0 } else { _theta-guide.angle },
      )
    } else { () }
  }
  let outer-radial = radial-ctx(
    coord,
    x-trained,
    y-trained,
    px-range,
    py-range,
    label-bounds: _label-bounds,
  )
  let is-radial = outer-radial != none

  let _panel = _rect-style(
    theme,
    "panel-background",
    fallback-fill: theme.paper,
    outset-ref-w: canvas-w,
    outset-ref-h: canvas-h,
  )
  // Panel rect stays glued to the natural panel canvas so a themed `inset`
  // cannot bleed past adjacent facets or chrome. Visible breathing room
  // around a panel is the job of `outset` (chrome reservation upstream).
  if _panel.fill != none or _panel.stroke != none {
    if is-radial {
      cetz.draw.circle(
        outer-radial.centre,
        radius: outer-radial.r-max,
        fill: _panel.fill,
        stroke: _panel.stroke,
      )
    } else {
      rect(
        (px-lo, py-lo),
        (px-hi, py-hi),
        fill: _panel.fill,
        stroke: _panel.stroke,
      )
    }
  }

  let _grid-stroke = surface => _line-stroke(
    theme,
    surface,
    fallback-colour: _ink,
  )
  let _grid-major = (
    x: _grid-stroke("panel-grid-major-x"),
    y: _grid-stroke("panel-grid-major-y"),
  )
  let _grid-minor = (
    x: _grid-stroke("panel-grid-minor-x"),
    y: _grid-stroke("panel-grid-minor-y"),
  )
  // Radial panels draw one grid weight for both circles and spokes; the
  // per-axis split and minor lines apply to cartesian panels only.
  let _grid-radial = _grid-stroke("panel-grid-major")
  let _stroke-side = (p, s, _) => _line-stroke(
    theme,
    p + "-" + s,
    fallback-colour: _ink,
  )
  let _ax-line = _per-side(_stroke-side, "axis-line")
  let _ax-ticks = _per-side(_stroke-side, "axis-ticks")
  let _len-side = (p, s, _) => _tick-length(theme, p + "-" + s) / 1cm
  let _tick-len = _per-side(_len-side, "axis-ticks")

  let x-guide = _read-axis-guide(spec, "x", default-angle: _axis-text-angle(
    theme,
    "x",
  ))
  let y-guide = _read-axis-guide(spec, "y", default-angle: _axis-text-angle(
    theme,
    "y",
  ))
  // Pre-compute row metadata for each axis: the sub-guide, the cumulative
  // dodge offset (in row units) up to this sub-guide, and the inter-row gap
  // offset (in cm). Lifted out of the per-break draw loops so flat plots
  // walk a single tuple instead of rebuilding it every label.
  let _stack-rows(g, gap) = {
    let rows = _axis-guide-rows(g)
    let spacing = if g.stack { g.spacing } else { 0 }
    let row-base = 0
    let metas = ()
    for (i, sub) in rows.enumerate() {
      metas.push((sub: sub, dodge-base: row-base, stack-offset: i * spacing))
      row-base += sub.n-dodge
    }
    metas
  }
  let _x-rows = _stack-rows(x-guide, _X-LABEL-ROW-GAP)
  let _y-rows = _stack-rows(y-guide, _Y-LABEL-COL-GAP)
  let _draw-x-label(cx, label-text, idx) = {
    if not (show-x-labels and _ax-text.xb.size > 0pt) { return }
    for r in _x-rows {
      let dodge-row = calc.rem(idx, r.sub.n-dodge)
      let cy = (
        py-lo
          - _tick-len.xb
          - _TICK-LABEL-GAP
          - (r.dodge-base + dodge-row) * _X-LABEL-ROW-GAP
          - r.stack-offset
      )
      content(
        (cx, cy),
        text(.._text-args(_ax-text.xb))[#label-text],
        anchor: _x-label-anchor(r.sub.angle),
        angle: r.sub.angle * 1deg,
      )
    }
  }
  let _draw-y-label(cy, label-text, idx) = {
    if not (show-y-labels and _ax-text.yl.size > 0pt) { return }
    for r in _y-rows {
      let dodge-col = calc.rem(idx, r.sub.n-dodge)
      let cx = (
        px-lo
          - _tick-len.yl
          - _TICK-LABEL-GAP
          - (r.dodge-base + dodge-col) * _Y-LABEL-COL-GAP
          - r.stack-offset
      )
      content(
        (cx, cy),
        text(.._text-args(_ax-text.yl))[#label-text],
        anchor: "mid-east",
        angle: r.sub.angle * 1deg,
      )
    }
  }

  let _axis-display(trained) = (
    typst-mark: if trained != none {
      trained.at("typst-mark", default: false)
    } else { false },
    labels: spec-attr(trained, "labels", fallback: auto),
  )
  let _x-disp = _axis-display(x-trained)
  let _y-disp = _axis-display(y-trained)

  // Draw the cartesian axis ticks, gridlines, and labels for one axis.
  // Continuous and discrete axes share everything except how `cx`/`cy` is
  // mapped, where the labels come from, and whether gridlines are drawn
  // (continuous only, since discrete ticks already mark every level).
  let _draw-cartesian-axis(axis, trained, disp, ax-text-typst, draw-label) = {
    if is-radial or trained == none { return }
    let is-continuous = trained.type == "continuous"
    if not is-continuous and trained.type != "discrete" { return }
    let stroke = if axis == "x" { _ax-ticks.xb } else { _ax-ticks.yl }
    let tick-len = if axis == "x" { _tick-len.xb } else { _tick-len.yl }
    let suppress = if axis == "x" { x-guide.suppress } else { y-guide.suppress }
    let range = if axis == "x" { px-range } else { py-range }
    let major-stroke = if axis == "x" { _grid-major.x } else { _grid-major.y }
    let minor-stroke = if axis == "x" { _grid-minor.x } else { _grid-minor.y }
    let cached = if axis-breaks == none { none } else {
      axis-breaks.at(axis, default: none)
    }
    let breaks = if is-continuous and cached != none {
      cached
    } else { _axis-tick-values(trained) }
    // Minor gridlines sit under the majors, so draw them first.
    if is-continuous and minor-stroke != none {
      for mb in _axis-minor-breaks(trained, breaks) {
        let mc = map-axis-data(trained, mb, range)
        if axis == "x" {
          line((mc, py-lo), (mc, py-hi), stroke: minor-stroke)
        } else {
          line((px-lo, mc), (px-hi, mc), stroke: minor-stroke)
        }
      }
    }
    for (idx, b) in breaks.enumerate() {
      let c = map-break(trained, b, range)
      if is-continuous and major-stroke != none {
        if axis == "x" {
          line((c, py-lo), (c, py-hi), stroke: major-stroke)
        } else {
          line((px-lo, c), (px-hi, c), stroke: major-stroke)
        }
      }
      if _should-draw-tick(stroke, tick-len) and not suppress {
        if axis == "x" {
          line((c, py-lo), (c, py-lo - tick-len), stroke: stroke)
        } else {
          line((px-lo - tick-len, c), (px-lo, c), stroke: stroke)
        }
      }
      if not suppress {
        let fallback = _tick-label-fallback(trained, b)
        draw-label(
          c,
          resolve-prose(
            resolve-label(
              disp.labels,
              b,
              idx,
              fallback,
              typst-mark: disp.typst-mark,
            ),
            eval-strings: ax-text-typst,
          ),
          idx,
        )
      }
    }
  }
  _draw-cartesian-axis(
    "x",
    x-trained,
    _x-disp,
    _ax-text.xb.typst,
    _draw-x-label,
  )
  _draw-cartesian-axis(
    "y",
    y-trained,
    _y-disp,
    _ax-text.yl.typst,
    _draw-y-label,
  )

  // Minor log ticks: opt-in via guide-axis-logticks() on a log10-trans axis.
  // Emits unlabelled ticks at sub-decade positions (2, 3, ..., 9 within each
  // decade) covered by the visible domain, themed via `axis-ticks-minor`
  // (default: half the resolved `axis-ticks` length, same stroke).
  let _draw-log-minors(trained, guide, axis, range) = {
    if not guide.logticks or guide.suppress { return }
    if trained == none { return }
    if trained.type != "continuous" { return }
    if trained.at("transform", default: "identity") != "log10" { return }
    let surface = "axis-ticks-minor-" + axis
    let stroke = _line-stroke(theme, surface, fallback-colour: _ink)
    let minor-len = _tick-length(theme, surface) / 1cm
    if not _should-draw-tick(stroke, minor-len) { return }
    let view-transform = trained.at("view-transform", default: none)
    let (lo, hi) = if view-transform != none {
      (
        transform-inv("log10", view-transform.at(0)),
        transform-inv("log10", view-transform.at(1)),
      )
    } else { trained.domain }
    if lo <= 0 or hi <= 0 { return }
    for v in _log10-minor-positions(lo, hi) {
      if axis == "x" {
        let cx = map-axis-data(trained, v, range)
        line((cx, py-lo), (cx, py-lo - minor-len), stroke: stroke)
      } else {
        let cy = map-axis-data(trained, v, range)
        line((px-lo - minor-len, cy), (px-lo, cy), stroke: stroke)
      }
    }
  }
  if not is-radial {
    _draw-log-minors(x-trained, x-guide, "x", px-range)
    _draw-log-minors(y-trained, y-guide, "y", py-range)
  }

  // Secondary x-axis: draw on top edge if the trained x scale carries a
  // secondary spec. Breaks are its own when set, else the primary axis grid;
  // their labels go through the user's transformation function.
  let _x-sec = _sec-spec(x-trained, coord: coord)
  if _x-sec != none and show-x-sec {
    let breaks = if axis-breaks != none and axis-breaks.x-sec != none {
      axis-breaks.x-sec
    } else {
      _secondary-breaks(x-trained, _x-sec, _axis-breaks(x-trained))
    }
    for (idx, b) in breaks.enumerate() {
      let cx = map-axis-data(x-trained, b, px-range)
      if _should-draw-tick(_ax-ticks.xt, _tick-len.xt) {
        line((cx, py-hi), (cx, py-hi + _tick-len.xt), stroke: _ax-ticks.xt)
      }
      if _ax-text.xt.size > 0pt {
        let mapped = secondary-mod.apply-transform(_x-sec, b)
        content(
          (cx, py-hi + _tick-len.xt + _TICK-LABEL-GAP),
          text(.._text-args(_ax-text.xt))[#resolve-prose(
            resolve-label(
              _x-sec.at("labels", default: auto),
              mapped,
              idx,
              format-break(mapped),
              typst-mark: _x-disp.typst-mark,
            ),
            eval-strings: _ax-text.xt.typst,
          )],
          anchor: "south",
        )
      }
    }
    if _ax-line.xt != none {
      line((px-lo, py-hi), (px-hi, py-hi), stroke: _ax-line.xt)
    }
    if show-x-sec-title and _x-sec.name != none and _ax-title.xt.size > 0pt {
      let x-sec-offset = _sec-title-offset-cm(
        _tick-len.xt,
        _resolve-extents(x-sec-extents, _ax-text.xt.size),
        _ax-title.xt,
        "x",
      )
      let (cx, x-anchor) = _x-title-place(_ax-title.xt.align, px-lo, px-hi)
      content(
        (cx, py-hi + x-sec-offset),
        _title-body(
          _x-sec.name,
          _ax-title.xt,
          x-sec-title-extents,
        ),
        anchor: x-anchor,
        angle: _title-angle(_ax-title.xt, 0),
      )
    }
  }

  // Secondary y-axis: draw on right edge if the trained y scale carries a
  // secondary spec.
  let _y-sec = _sec-spec(y-trained, coord: coord)
  if _y-sec != none and show-y-sec {
    let breaks = if axis-breaks != none and axis-breaks.y-sec != none {
      axis-breaks.y-sec
    } else {
      _secondary-breaks(y-trained, _y-sec, _axis-breaks(y-trained))
    }
    for (idx, b) in breaks.enumerate() {
      let cy = map-axis-data(y-trained, b, py-range)
      if _should-draw-tick(_ax-ticks.yr, _tick-len.yr) {
        line((px-hi, cy), (px-hi + _tick-len.yr, cy), stroke: _ax-ticks.yr)
      }
      if _ax-text.yr.size > 0pt {
        let mapped = secondary-mod.apply-transform(_y-sec, b)
        content(
          (px-hi + _tick-len.yr + _TICK-LABEL-GAP, cy),
          text(.._text-args(_ax-text.yr))[#resolve-prose(
            resolve-label(
              _y-sec.at("labels", default: auto),
              mapped,
              idx,
              format-break(mapped),
              typst-mark: _y-disp.typst-mark,
            ),
            eval-strings: _ax-text.yr.typst,
          )],
          anchor: "mid-west",
        )
      }
    }
    if _ax-line.yr != none {
      line((px-hi, py-lo), (px-hi, py-hi), stroke: _ax-line.yr)
    }
    if show-y-sec-title and _y-sec.name != none and _ax-title.yr.size > 0pt {
      let y-sec-offset = _sec-title-offset-cm(
        _tick-len.yr,
        _resolve-extents(y-sec-extents, _ax-text.yr.size),
        _ax-title.yr,
        "y",
      )
      let title-text-cm = _title-extent-cm(
        _ax-title.yr,
        y-sec-title-extents,
        "y",
      )
      let (cy, y-anchor) = _y-title-place(_ax-title.yr.align, py-lo, py-hi)
      content(
        (px-hi + y-sec-offset + title-text-cm / 2, cy),
        _title-body(
          _y-sec.name,
          _ax-title.yr,
          y-sec-title-extents,
        ),
        angle: _title-angle(_ax-title.yr, 90),
        anchor: y-anchor,
      )
    }
  }

  if not is-radial and _ax-line.xb != none {
    line((px-lo, py-lo), (px-hi, py-lo), stroke: _ax-line.xb)
  }
  if not is-radial and _ax-line.yl != none {
    line((px-lo, py-lo), (px-lo, py-hi), stroke: _ax-line.yl)
  }

  if is-radial {
    _draw-radial-panel((
      spec: spec,
      outer-radial: outer-radial,
      x-trained: x-trained,
      y-trained: y-trained,
      x-disp: _x-disp,
      y-disp: _y-disp,
      ax-text: _ax-text,
      grid-radial: _grid-radial,
      ax-line: _ax-line,
      show-x-labels: show-x-labels,
    ))
  }

  // Render geoms into a sibling cetz canvas whose origin is (0, 0) and whose
  // bounds match the panel rectangle, then clip via Typst's `box(clip: true)`
  // before placing it back at the panel's south-west corner. cetz 0.5.0 has
  // no native clip primitive, so this nested-canvas hop is the only way to
  // bound geom marks to the panel.
  // Floored at zero: `box(clip: true, width: panel-w * 1cm, ...)` below is the
  // one place a negative extent would reach Typst.
  let panel-w = calc.max(0.0, px-hi - px-lo)
  let panel-h = calc.max(0.0, py-hi - py-lo)
  let inner-ctx = ctx
  inner-ctx.px-range = (x-pad-lo, panel-w - x-pad-hi)
  inner-ctx.py-range = (y-pad-lo, panel-h - y-pad-hi)
  let inner-radial = radial-ctx(
    coord,
    x-trained,
    y-trained,
    inner-ctx.px-range,
    inner-ctx.py-range,
    label-bounds: _label-bounds,
  )
  inner-ctx.radial = inner-radial
  if inner-radial != none {
    for layer in prepared {
      if not _RADIAL-AWARE.at(layer.name, default: false) {
        fail("coord-radial", "does not support geom-" + layer.name)
      }
    }
  }
  // Every geom is drawn `floating`, so it never contributes to the canvas
  // bounds; only the `hide(rect ...)` does. Each subset canvas is therefore
  // exactly panel-sized with its origin at the south-west corner, so the
  // clipped and unclipped passes overlay in perfect register.
  let _draw-subset = subset => cetz.canvas({
    import cetz.draw: floating, hide, rect
    hide(rect((0, 0), (panel-w, panel-h)), bounds: true)
    for layer in subset {
      let draw = _geom-draw.at(layer.name, default: none)
      if draw != none {
        floating({ draw(layer, inner-ctx) })
      }
    }
  })
  // `annotate(clip: false)` opts a layer out of the panel clip; render it in a
  // sibling pass with no clip box so it can overflow the panel deliberately.
  // The sibling pass paints after the clipped one, so unclipped marks always
  // sit above clipped layers (documented on `annotate`'s `clip`).
  let clipped = prepared.filter(l => l.at("clip", default: true))
  let unclipped = prepared.filter(l => not l.at("clip", default: true))
  let clip-on = if inner-radial != none {
    inner-radial.clip
  } else if coord != none {
    coord.at("clip", default: true)
  } else { true }
  let clipped-geoms = _draw-subset(clipped)
  content(
    (px-lo, py-lo),
    if clip-on {
      box(
        clip: true,
        width: panel-w * 1cm,
        height: panel-h * 1cm,
        clipped-geoms,
      )
    } else { clipped-geoms },
    anchor: "south-west",
  )
  if unclipped.len() > 0 {
    content((px-lo, py-lo), _draw-subset(unclipped), anchor: "south-west")
  }

  // Radial-axis tick labels render after geoms so filled wedges, lines, and
  // points cannot mask them.
  if is-radial {
    _draw-radial-r-labels((
      spec: spec,
      outer-radial: outer-radial,
      x-trained: x-trained,
      y-trained: y-trained,
      x-disp: _x-disp,
      y-disp: _y-disp,
      ax-text: _ax-text,
      show-y-labels: show-y-labels,
    ))
  }

  // When flipped, the bottom axis shows the user's original y mapping and
  // the left axis shows the user's original x mapping; trained.x and
  // trained.y already carry the swapped scale specs (and labels labels), so
  // only the mapping-name fallback needs an explicit swap here.
  let _mapping-x-name = if spec.mapping == none { none } else if flipped {
    mapping-display-name(spec.mapping.at("y", default: none))
  } else { mapping-display-name(spec.mapping.at("x", default: none)) }
  let _mapping-y-name = if spec.mapping == none { none } else if flipped {
    mapping-display-name(spec.mapping.at("x", default: none))
  } else { mapping-display-name(spec.mapping.at("y", default: none)) }
  let x-title = _axis-title(x-trained, _mapping-x-name)
  let y-title = _axis-title(y-trained, _mapping-y-name)
  let x-title-cm = _title-extent-cm(_ax-title.xb, x-title-extents, "x")
  let y-title-cm = _title-extent-cm(_ax-title.yl, y-title-extents, "y")
  let x-title-gap = _text-margin-cm(_ax-title.xb, "top", _AX-TITLE-LABEL-GAP)
  let y-title-gap = _text-margin-cm(_ax-title.yl, "right", _AX-TITLE-LABEL-GAP)
  // A suppressed axis (`guides(x: none)`) draws no ticks or labels and a radial
  // panel draws neither band outside the panel, so in both cases the title
  // slides up to the panel edge. Both gates already ran in `_chrome-margins`,
  // which is why the band arrives rather than being derived a second time.
  let x-edge-offset = x-edge-band + x-title-gap
  let y-edge-offset = y-edge-band + y-title-gap
  if show-x-title and x-title != none and _ax-title.xb.size > 0pt {
    let (cx, x-anchor) = _x-title-place(_ax-title.xb.align, px-lo, px-hi)
    content(
      (cx, oy - (x-edge-offset + x-title-cm)),
      _title-body(
        x-title,
        _ax-title.xb,
        x-title-extents,
      ),
      anchor: x-anchor,
      angle: _title-angle(_ax-title.xb, 0),
    )
  }
  if show-y-title and y-title != none and _ax-title.yl.size > 0pt {
    let (cy, y-anchor) = _y-title-place(_ax-title.yl.align, py-lo, py-hi)
    content(
      (px-lo - (y-edge-offset + y-title-cm / 2), cy),
      _title-body(
        y-title,
        _ax-title.yl,
        y-title-extents,
      ),
      angle: _title-angle(_ax-title.yl, 90),
      anchor: y-anchor,
    )
  }

  if guides.len() > 0 and legend-args != none {
    legend-mod.draw(
      guides,
      ctx,
      panel-rect: legend-args.panel-rect,
      margin: legend-args.margin,
      legend-gap: legend-args.legend-gap,
      sec-y-extent: legend-args.sec-y-extent,
      sec-x-extent: legend-args.sec-x-extent,
      right-strip: legend-args.right-strip,
      theme: theme,
    )
  }
}

