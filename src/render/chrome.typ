// Chrome-margin stage: measures axis labels, titles, and secondary axes,
// folds in legend extents and themed surface outsets, and assembles the
// four-side panel margin consumed by the canvas builders. Pulled out of
// `render-plot-deferred` so the orchestrator reads as a pipeline.

#import "../scale/train.typ": mapping-display-name
#import "../theme/theme.typ": _rect-outset-cm, _text-style, _tick-length
#import "../utils/margin.typ": opposite-side, perpendicular-sides
#import "../utils/radial.typ": is-radial
#import "common.typ": _per-side
#import "axis-format.typ": _axis-title, _sec-spec
#import "guides.typ": _axis-text-angle, _read-axis-guide, _read-theta-guide
#import "domain.typ": _is-flipped
#import "../utils/errors.typ": fail
#import "extents.typ": (
  _AX-TITLE-LABEL-GAP, _axis-label-extents, _axis-title-extents,
  _fit-title-extents, _sec-extent, _secondary-label-extents, _text-margin-cm,
  _theta-label-margins, _title-angle, _title-extent-cm, _title-overrun-cm,
  _title-span-cm, _x-label-depth-stack, _y-label-width-stack,
)

// Passes allowed when settling axis-title wrapping against the panel size, and
// the cm below which two panel extents count as the same. Real plots settle in
// two or three; the cap only bounds a degenerate one.
#let _TITLE-FIT-PASSES = 8
#let _TITLE-FIT-TOLERANCE = 1e-6

// Compute the chrome margin and every measured extent the canvas builders
// need. `ctx` carries: `spec`, `theme`, `trained`, `coord`, `guides`,
// `extents` (legend side extents), `legend-gap`, `width-units`,
// `height-units`, `facet-grid-mode`, `free-x`, `free-y`, `grid-n-rows`,
// `grid-n-cols`, `panel-trained-list`, `margin-override`.
#let _chrome-margins(ctx) = {
  let spec = ctx.spec
  let theme = ctx.theme
  let trained = ctx.trained
  let coord = ctx.coord
  let guides = ctx.guides
  let extents = ctx.extents
  let legend-gap = ctx.legend-gap
  let width-units = ctx.width-units
  let height-units = ctx.height-units
  let panel-trained-list = ctx.panel-trained-list

  let x-trained-top = trained.at("x", default: none)
  let y-trained-top = trained.at("y", default: none)
  // A radial panel draws no secondary axis at all (`_draw-axis-and-layers`
  // gates the whole secondary block on `not is-radial`), so reserving its
  // ticks, labels, gap, and title would donate panel area to a margin nothing
  // draws in. Drop the spec here and every downstream measurement, extent, and
  // title side falls away with it, mirroring the draw-side gate.
  let _radial = is-radial(coord)
  let x-sec = if _radial { none } else { _sec-spec(x-trained-top) }
  let y-sec = if _radial { none } else { _sec-spec(y-trained-top) }
  let _surface-style = (p, s, _) => _text-style(theme, p + "-" + s)
  let _len-side = (p, s, _) => _tick-length(theme, p + "-" + s) / 1cm
  let tick-len = _per-side(_len-side, "axis-ticks")
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
    ctx.facet-grid-mode and ctx.free-x and panel-trained-list.len() > 0
  ) {
    let exts = range(ctx.grid-n-cols).map(c => _axis-label-extents(
      panel-trained-list
        .at((ctx.grid-n-rows - 1) * ctx.grid-n-cols + c)
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
    ctx.facet-grid-mode and ctx.free-y and panel-trained-list.len() > 0
  ) {
    let exts = range(ctx.grid-n-rows).map(r => _axis-label-extents(
      panel-trained-list.at(r * ctx.grid-n-cols).at("y", default: none),
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
  // A side whose `axis-text` is blank (`theme-void`, or a per-side
  // `element-blank()`) draws no labels, so it reserves no perpendicular depth
  // for them; otherwise the chrome margin reserves space for ink that never
  // draws, inverting the panel rect on small plot sizes.
  let x-label-depth = if ax-text.xb.size > 0pt and not x-guide.suppress {
    _x-label-depth-stack(x-guide, x-extents.width, x-extents.height)
  } else { 0.0 }
  let y-label-width = if ax-text.yl.size > 0pt and not y-guide.suppress {
    _y-label-width-stack(y-guide, y-extents.width, y-extents.height)
  } else { 0.0 }
  // Theta tick labels ring the circle instead of sitting under one edge, so a
  // radial panel owes every margin the band they land in. The angular axis is
  // x unless the coord says otherwise, and `guides(theta: ...)` carries their
  // rotation and their suppress marker, exactly as the draw site reads them.
  let theta-margins = if not _radial {
    (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0)
  } else {
    let theta-guide = _read-theta-guide(spec)
    let cat-is-theta = coord.at("theta", default: "x") == "x"
    let theta-text = if cat-is-theta { ax-text.xb } else { ax-text.yl }
    let theta-extents = if cat-is-theta { x-extents } else { y-extents }
    if (
      theta-text.size > 0pt
        and not (theta-guide != none and theta-guide.suppress)
    ) {
      _theta-label-margins(
        theta-extents,
        if theta-guide == none { 0 } else { theta-guide.angle },
      )
    } else { (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0) }
  }

  // A suppressed (`labels(x: none)`) or nameless axis title reserves no extent;
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
  let x-sec-title = if x-sec == none { none } else {
    x-sec.at("name", default: none)
  }
  let y-sec-title = if y-sec == none { none } else {
    y-sec.at("name", default: none)
  }
  // The four titles take identical treatment and differ only in their text
  // style, which panel dimension bounds them, and how a failure names them.
  // Keyed as `ax-title` is so the fitted extents travel back out by side.
  let title-sides = (
    (key: "xb", title: x-title, style: ax-title.xb, axis: "x", name: "x-axis"),
    (key: "yl", title: y-title, style: ax-title.yl, axis: "y", name: "y-axis"),
    (
      key: "xt",
      title: x-sec-title,
      style: ax-title.xt,
      axis: "x",
      name: "secondary x-axis",
    ),
    (
      key: "yr",
      title: y-sec-title,
      style: ax-title.yr,
      axis: "y",
      name: "secondary y-axis",
    ),
  )
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
  // A suppressed axis (`guides(x: none)`) draws no ticks or labels, so it
  // reserves no tick depth either; the axis line and title still render.
  let x-tick-cm = if x-guide.suppress { 0.0 } else { tick-len.xb }
  let y-tick-cm = if y-guide.suppress { 0.0 } else { tick-len.yl }
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

  // Everything above is independent of how the axis titles wrap. The margin is
  // not: a title is boxed to the reading length the panel leaves it, a wrapped
  // title is thicker than one line, a thicker title takes more margin, and a
  // bigger margin leaves the panel smaller again. Solve it by iterating from
  // the unwrapped state, which is the largest panel any pass can produce.
  // `along-cm: none` there reproduces the pre-wrapping measurement exactly, so
  // a plot whose titles all fit re-measures to the same extents on the second
  // pass, settles against them, and keeps its former layout to the bit.
  let _fit(along) = {
    // Measure the title ink so its rotated bounding box reserves the right
    // perpendicular extent at any angle, mirroring the tick-label measurement.
    let ext = (:)
    for side in title-sides {
      ext.insert(side.key, _axis-title-extents(
        side.title,
        side.style,
        along-cm: along.at(side.key),
      ))
    }
    let sec-x-extent = _sec-extent(
      x-sec,
      tick-len.xt,
      x-sec-extents,
      ax-title.xt,
      "x",
      title-ext: ext.xt,
    )
    let sec-y-extent = _sec-extent(
      y-sec,
      tick-len.yr,
      y-sec-extents,
      ax-title.yr,
      "y",
      title-ext: ext.yr,
    )
    let x-title-cm = if x-title != none {
      _title-extent-cm(ax-title.xb, ext.xb, "x")
    } else { 0.0 }
    let y-title-cm = if y-title != none {
      _title-extent-cm(ax-title.yl, ext.yl, "y")
    } else { 0.0 }
    let bottom-extent = calc.max(
      x-tick-cm + 0.1 + x-label-depth + bottom-gap + x-title-cm + 0.05,
      theta-margins.bottom,
    )
    let left-extent = calc.max(
      y-tick-cm + 0.1 + y-label-width + left-gap + y-title-cm,
      theta-margins.left,
    )
    // Cap the right margin so the legend can never push panel width below the
    // single-tick minimum. Without the cap, `px-hi - px-lo` goes negative and
    // axis labels render reversed (panel becomes mirror-imaged into the legend).
    let max-right-margin = calc.max(0.0, width-units - left-extent - 0.5)
    (
      margin: (
        left: left-extent + _side-gap("left") + _surface-out("left"),
        bottom: bottom-extent + _side-gap("bottom") + _surface-out("bottom"),
        top: (
          calc.max(sec-x-extent, theta-margins.top)
            + _side-gap("top")
            + _surface-out("top")
        ),
        right: calc.min(
          calc.max(sec-y-extent, theta-margins.right)
            + _side-gap("right")
            + _surface-out("right"),
          max-right-margin,
        ),
      ),
      max-right-margin: max-right-margin,
      sec-x-extent: sec-x-extent,
      sec-y-extent: sec-y-extent,
      ext: ext,
    )
  }

  // Each pass may only tighten a bound, never loosen one; erring small merely
  // over-reserves, since a box narrower than the panel cannot overrun it.
  let _tighten(prev, next) = if next == none {
    prev
  } else if prev == none { next } else { calc.min(prev, next) }

  // The bound is solved from the title's unwrapped width, which does not move
  // as the panel does, so measure it once rather than once per pass.
  let natural = (:)
  for side in title-sides {
    natural.insert(side.key, _axis-title-extents(side.title, side.style).width)
  }

  let along = (xb: none, yl: none, xt: none, yr: none)
  let fit = _fit(along)
  let panel-w = 0.0
  let panel-h = 0.0
  // Each pass can only take panel extent away, never give it back, so the
  // sequence descends and is bounded below by zero: it settles. Stop once the
  // panel holds still AND every title fits the span it was bounded to; the cap
  // is a backstop for a degenerate plot, where the panel floors in `_fit` and
  // the canvas-minimum guard in `render-plot` takes over.
  for _ in range(_TITLE-FIT-PASSES) {
    let next-w = calc.max(0.0, width-units - fit.margin.left - fit.margin.right)
    let next-h = calc.max(
      0.0,
      height-units - fit.margin.top - fit.margin.bottom,
    )
    let settled = (
      calc.abs(next-w - panel-w) < _TITLE-FIT-TOLERANCE
        and calc.abs(next-h - panel-h) < _TITLE-FIT-TOLERANCE
    )
    let fitted = title-sides.all(side => {
      let panel-cm = if side.axis == "x" { next-w } else { next-h }
      let span = _title-span-cm(side.style, fit.ext.at(side.key), side.axis)
      span <= panel-cm + _TITLE-FIT-TOLERANCE
    })
    if settled and fitted { break }
    panel-w = next-w
    panel-h = next-h
    for side in title-sides {
      let panel-cm = if side.axis == "x" { panel-w } else { panel-h }
      along.insert(side.key, _tighten(
        along.at(side.key),
        _fit-title-extents(
          side.title,
          side.style,
          side.axis,
          panel-cm,
          natural.at(side.key),
        ).along,
      ))
    }
    fit = _fit(along)
  }

  // Two ways wrapping can fail to rescue a title, both of which would push the
  // canvas past the requested size. Say so rather than ship a figure that
  // silently outgrows the box it was given.
  let _cm = v => str(calc.round(v, digits: 2))
  for side in title-sides {
    let ext = fit.ext.at(side.key)
    let panel-cm = if side.axis == "x" { panel-w } else { panel-h }
    // A word wider than the box it wraps in.
    if _title-overrun-cm(ext) > _TITLE-FIT-TOLERANCE {
      fail(
        "plot",
        "the "
          + side.name
          + " title has a "
          + _cm(ext.min-width)
          + " cm word that cannot wrap into the "
          + _cm(ext.along)
          + " cm the panel leaves it",
        hint: "Shorten the title, break it with `\\`, or give the plot more "
          + "room with `width`/`height`.",
      )
    }
    // A title rotated off its axis spans the panel with both its length and
    // its thickness, and narrowing the box trades one for the other. Past a
    // point that trade stops paying and no box fits at all.
    let span = _title-span-cm(side.style, ext, side.axis)
    if span > panel-cm + _TITLE-FIT-TOLERANCE {
      let default-deg = if side.axis == "x" { 0 } else { 90 }
      fail(
        "plot",
        "the "
          + side.name
          + " title spans "
          + _cm(span)
          + " cm along a panel of "
          + _cm(panel-cm)
          + " cm, and no wrapping of it at "
          + str(calc.round(
            _title-angle(side.style, default-deg).deg(),
            digits: 1,
          ))
          + "deg spans less",
        hint: "Shorten the title, return it to its natural angle, reduce its "
          + "font size, or give the plot more room with `width`/`height`.",
      )
    }
  }

  let margin = fit.margin
  // `compose(align-panels: true)` forces a shared margin so panels' plot areas
  // line up; overlay the supplied sides, then clamp every side against this
  // panel's own extent so a forced margin can never invert the plot rect. Each
  // bound keeps at least 0.5cm of plot opposite it, matching `max-right-margin`.
  if ctx.margin-override != none {
    margin = margin + ctx.margin-override
    margin.right = calc.min(margin.right, fit.max-right-margin)
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

  (
    margin: margin,
    ax-text: ax-text,
    x-extents: x-extents,
    y-extents: y-extents,
    x-sec-extents: x-sec-extents,
    y-sec-extents: y-sec-extents,
    sec-x-extent: fit.sec-x-extent,
    sec-y-extent: fit.sec-y-extent,
    x-title-extents: fit.ext.xb,
    y-title-extents: fit.ext.yl,
    x-sec-title-extents: fit.ext.xt,
    y-sec-title-extents: fit.ext.yr,
  )
}
