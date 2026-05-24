#import "render.typ": render-plot-deferred
#import "legend.typ" as legend-mod
#import "theme/current.typ": _theme-state
#import "theme/defaults.typ": merge-theme
#import "theme/elements.typ": margin

// The public `compose` parameter `layout` shadows Typst's builtin `layout`
// function inside the body; capture the builtin here so the container size is
// still reachable.
#let _layout = layout

#let _is-plot-spec(x) = (
  type(x) == dictionary
    and "layers" in x
    and "data" in x
    and "width" in x
    and "height" in x
    and "guides" in x
)

#let _index-by-aesthetic(guides) = {
  let out = (:)
  for g in guides {
    for a in g.at("aesthetics", default: ()) {
      out.insert(a, g)
    }
  }
  out
}

#let _all-mergeable(per-panel, aes-name) = {
  let first = none
  for idx in per-panel {
    let g = idx.at(aes-name, default: none)
    if g == none { return false }
    if first == none {
      first = g
    } else if not legend-mod.can-merge-cross-panel(first, g) {
      return false
    }
  }
  first != none
}

// Compose's heuristic sizing pass uses the default 9pt body. The visible
// legend is re-rendered via `standalone()` later with the actual theme.
#let _COMPOSE-SIZE-PT = 9

#let _coerce-placement(g, side) = legend-mod.recompute-extent(
  (
    ..g,
    placement: (
      ..g.placement,
      side: side,
      direction: if side == "top" or side == "bottom" {
        "horizontal"
      } else { "vertical" },
    ),
  ),
  _COMPOSE-SIZE-PT,
)

#let _legend-canvas-size(guides, side) = {
  let extents = legend-mod.estimate-extents(guides)
  if side == "right" or side == "left" {
    let height = 0.0
    for g in guides { height += g.at("height", default: 0.0) + 0.2 }
    (width: extents.at(side), height: height)
  } else {
    let width = 0.0
    for g in guides { width += g.at("width", default: 0.0) + 0.15 }
    (width: width, height: extents.at(side))
  }
}

// Split `total` cm into `count` track lengths separated by `gutter` cm gaps,
// distributed by `ratios` (relative weights) or equally when `ratios` is
// `none`. Returns an array of cm floats summing to `total - gutter * (count -
// 1)`.
#let _tracks(total, count, gutter, ratios) = {
  let usable = calc.max(total - gutter * (count - 1), 0.0)
  let weights = if ratios == none {
    range(count).map(_ => 1.0)
  } else {
    ratios.map(r => float(r))
  }
  let sum = weights.fold(0.0, (a, b) => a + b)
  weights.map(w => usable * w / sum)
}

/// Arrange multiple plots into a grid or stack with a shared, hoisted legend.
///
/// `compose` is the multi-plot orchestrator: it takes deferred plots, probes
/// each panel's would-be guides, decides which legends are identical across
/// every panel, lifts them into a single shared block on the requested side,
/// and re-renders the panels with the hoisted aesthetics suppressed so each
/// reclaims the margin its legend would have occupied. Inspired by
/// `patchwork::plot_layout(guides = "collect")`.
///
/// Every positional argument must be a deferred plot (`plot(..., defer: true)`);
/// passing rendered content panics, because compose needs the spec to re-render.
///
/// \@category Core
/// \@stability stable
/// \@since 0.0.1
///
/// \@param ..panels-positional Two or more deferred plots produced by\@plot with
///   `defer: true`. Order is preserved by the layout (left-to-right, top-to-bottom
///   for grids; per `dir` for stacks).
///
/// \@param layout `"grid"` (default) lays panels into a Typst `grid` with `columns`
///   columns; `"stack"` lays them into a Typst `stack` flowing in `dir`.
///
/// \@param columns Number of columns in `"grid"` layout. Ignored for `"stack"`.
///
/// \@param direction Stack direction (`ttb`, `btt`, `ltr`, `rtl`) used by
///   `"stack"` layout. Ignored for `"grid"`.
///
/// \@param gutter Spacing between panels and between the panel block and the
///   shared legend.
///
/// \@param widths Relative column widths (grid) or panel widths along a
///   horizontal stack, as an array of weights (e.g. `(2, 1)`). When set, the
///   child plots' own `width`/`height` are discarded and panels fill their
///   cells. Length must match the column count. Requires a bounded composition
///   `width`.
///
/// \@param heights Relative row heights (grid) or panel heights along a
///   vertical stack. Same rules as `widths`; length must match the row count
///   and it requires a bounded composition `height`.
///
/// \@param width Total composition width. `auto` (default) fills the available
///   width of a bounded container (resolved through Typst `layout`). When the
///   container is unbounded and `width` is `auto`, compose falls back to laying
///   panels at their own declared sizes.
///
/// \@param height Total composition height. Same semantics as `width`.
///
/// \@param collect Which aesthetics to hoist into the shared legend.
///   - `auto` (default) hoists every aesthetic whose guide is identical across
///     all panels (kind, title, levels/domain, breaks, labels, aesthetic mix).
///     Aesthetics that disagree on any of those fields stay per-plot, so a
///     mismatched panel never silently borrows another panel's legend.
///   - `none` disables hoisting entirely; each plot keeps its own legends.
///   - An array of aesthetic names (e.g., `("colour", "fill")`) restricts
///     hoisting to the listed aesthetics. Listed aesthetics that aren't
///     mergeable across panels still stay per-plot; non-listed aesthetics
///     are never hoisted regardless of agreement.
///   The merge predicate ignores per-panel placement and grid shape (`nrow` /
///   `ncol`); compose forces a single shared side and grid layout for the
///   hoisted block. Custom guides (`guide-custom`) never hoist.
///
/// \@param guides-placement Side where the shared legend appears, relative to
///   the panel block. One of `"right"` (default), `"left"`, `"top"`, or
///   `"bottom"`. The hoisted guides' direction is set automatically:
///   `"vertical"` for left/right, `"horizontal"` for top/bottom.
///
/// \@returns Typst content block: the panel layout with the shared legend
///   stacked on `guides-placement`, or the bare panel layout when no aesthetic
///   ends up hoisted.
///
/// \@examples Auto-collect: identical `colour` legend hoisted to the right.
/// ```
/// //| alt: "Two side-by-side mpg scatter panels sharing a single colour legend by cylinder count hoisted to the right of the panel grid."
/// #let panel(map) = plot(
///   data: mpg, mapping: map,
///   layers: (geom-point(size: 3pt),),
///   width: 6cm, height: 4cm, defer: true,
/// )
/// #compose(
///   panel(aes(x: "displ", y: "hwy", colour: as-factor("cyl"))),
///   panel(aes(x: "displ", y: "cty", colour: as-factor("cyl"))),
///   layout: "grid", columns: (auto, auto),
/// )
/// ```
///
/// \@examples Restrict hoisting: shared `colour` only, per-plot `size` ladders
/// stay in each panel.
/// ```
/// //| alt: "Two mpg scatter panels sharing a single colour-by-cylinder legend on the right while each panel keeps its own size legend bound to a different column."
/// #let panel(map) = plot(
///   data: mpg, mapping: map,
///   layers: (geom-point(),),
///   width: 6cm, height: 4cm, defer: true,
/// )
/// #compose(
///   panel(aes(x: "displ", y: "hwy", colour: as-factor("cyl"), size: "cty")),
///   panel(aes(x: "displ", y: "cty", colour: as-factor("cyl"), size: "hwy")),
///   layout: "grid", columns: (auto, auto),
///   collect: ("colour",),
/// )
/// ```
///
/// \@examples Place the shared legend below the panels.
/// ```
/// //| alt: "Two side-by-side mpg scatter panels sharing a single colour-by-cylinder legend placed horizontally below the panel grid."
/// #let panel(map) = plot(
///   data: mpg, mapping: map,
///   layers: (geom-point(size: 3pt),),
///   width: 6cm, height: 4cm, defer: true,
/// )
/// #compose(
///   panel(aes(x: "displ", y: "hwy", colour: as-factor("cyl"))),
///   panel(aes(x: "displ", y: "cty", colour: as-factor("cyl"))),
///   layout: "grid", columns: (auto, auto),
///   guides-placement: "bottom",
/// )
/// ```
///
/// \@examples Size the composition to a bounded box and split the two panels
/// 2:1 with `widths`; the child plots' own dimensions are discarded.
/// ```
/// //| alt: "Two mpg scatter panels in a 16 by 6 centimetre canvas where the left panel is twice the width of the right, sharing a colour-by-cylinder legend on the right."
/// #let panel(map) = plot(
///   data: mpg, mapping: map,
///   layers: (geom-point(size: 2pt),),
///   width: 6cm, height: 4cm, defer: true,
/// )
/// #box(width: 16cm, height: 6cm, compose(
///   panel(aes(x: "displ", y: "hwy", colour: as-factor("cyl"))),
///   panel(aes(x: "displ", y: "cty", colour: as-factor("cyl"))),
///   columns: 2, widths: (2, 1),
/// ))
/// ```
///
/// \@see\@plot,\@aes,\@guides
#let compose(
  ..panels-positional,
  layout: "grid",
  columns: 2,
  direction: ttb,
  gutter: 0.5cm,
  widths: none,
  heights: none,
  width: auto,
  height: auto,
  collect: auto,
  guides-placement: "right",
) = {
  let panels = panels-positional.pos()
  if panels.len() == 0 {
    panic("compose: at least one deferred plot is required")
  }
  for p in panels {
    if not _is-plot-spec(p) {
      panic(
        "compose: every positional argument must be `plot(..., defer: true)`; "
          + "got "
          + repr(p),
      )
    }
  }
  if collect != auto and collect != none and type(collect) != array {
    panic(
      "compose: `collect` must be `auto`, `none`, or an array of aesthetic names",
    )
  }
  if not ("right", "left", "top", "bottom").contains(guides-placement) {
    panic(
      "compose: guides-placement must be \"right\", \"left\", \"top\", or "
        + "\"bottom\"; got "
        + repr(guides-placement),
    )
  }
  if layout != "grid" and layout != "stack" {
    panic("compose: layout must be \"grid\" or \"stack\"; got " + repr(layout))
  }

  _layout(container => context {
    let probes = panels.map(spec => render-plot-deferred(spec))
    let per-panel = probes.map(p => _index-by-aesthetic(p.guides))

    let candidates = if collect == auto {
      let all = ()
      for idx in per-panel {
        for a in idx.keys() {
          if not all.contains(a) { all.push(a) }
        }
      }
      all
    } else if collect == none {
      ()
    } else {
      collect
    }

    let hoisted = ()
    let hoisted-guides = ()
    for a in candidates {
      if not _all-mergeable(per-panel, a) { continue }
      hoisted.push(a)
      let g = _coerce-placement(per-panel.first().at(a), guides-placement)
      // A merged guide (e.g., colour+fill on the same column) is reached
      // through every aesthetic it carries, so dedup by aesthetic mix.
      if not hoisted-guides.any(h => h.aesthetics == g.aesthetics) {
        hoisted-guides.push(g)
      }
    }

    // The panel butts up against the hoisted legend by passing `tight-sides`
    // to render-plot-deferred. `tight-sides` drops the conservative axis-side
    // floor (1.5 / 1.1 cm) on the hoisted side so the dynamic chrome shrinks
    // to just what the present decorations (axis title on left/bottom, none on
    // top/right) actually need.
    let tight-sides = (guides-placement,)

    let first-theme = panels.first().theme
    let theme = merge-theme(
      if first-theme != none { first-theme } else { _theme-state.get() },
    )

    // Legend footprint, reserved from the canvas in sized mode so the panel
    // block plus legend total back to the requested dimensions.
    let legend-size = if hoisted-guides.len() > 0 {
      _legend-canvas-size(hoisted-guides, guides-placement)
    } else { (width: 0.0, height: 0.0) }
    // For right placement the panel-margin override trims the panel's right
    // side to 0 cm; with no intrinsic cetz padding on that side the legend
    // would butt against the panel data area, so add `legend-gap` to match a
    // single-plot side-legend offset. Other sides leave the panel-block's own
    // axis-text / cetz-baseline padding to provide the visual gap.
    let right-gap-cm = if (
      hoisted-guides.len() > 0 and guides-placement == "right"
    ) { legend-mod.legend-gap(theme) } else { 0.0 }

    // `sized` when both axes are bounded: an explicit length, or `auto` inside
    // a bounded container. Otherwise compose falls back to intrinsic layout,
    // sizing each panel at its own declared `width`/`height` (the historical
    // behaviour) so an unwrapped composition still renders.
    let sized = (
      (width != auto or container.width.pt() < float.inf)
        and (height != auto or container.height.pt() < float.inf)
    )

    let panel-block = if sized {
      let area-w = (if width == auto { container.width } else { width }) / 1cm
      let area-h = (
        (
          if height == auto { container.height } else { height }
        )
          / 1cm
      )
      if guides-placement == "right" {
        area-w -= legend-size.width + right-gap-cm
      } else if guides-placement == "left" {
        area-w -= legend-size.width
      } else {
        area-h -= legend-size.height
      }

      let n = panels.len()
      // `widths`/`heights` make panels fill their cells; without them each
      // panel keeps its aspect ratio and is letterboxed in an equal cell.
      let fill-mode = widths != none or heights != none
      let cols = 0
      let rows = 0
      let col-ratios = none
      let row-ratios = none
      if layout == "grid" {
        cols = if type(columns) == int { columns } else { columns.len() }
        rows = calc.ceil(n / cols)
        col-ratios = widths
        row-ratios = heights
      } else if direction == ttb or direction == btt {
        cols = 1
        rows = n
        row-ratios = heights
      } else {
        cols = n
        rows = 1
        col-ratios = widths
      }
      if col-ratios != none and col-ratios.len() != cols {
        panic(
          "compose: `widths` needs one entry per column ("
            + str(cols)
            + "); got "
            + str(col-ratios.len()),
        )
      }
      if row-ratios != none and row-ratios.len() != rows {
        panic(
          "compose: `heights` needs one entry per row ("
            + str(rows)
            + "); got "
            + str(row-ratios.len()),
        )
      }

      let gutter-cm = gutter / 1cm
      let col-tracks = _tracks(area-w, cols, gutter-cm, col-ratios)
      let row-tracks = _tracks(area-h, rows, gutter-cm, row-ratios)

      let render-cell(spec, cell-w, cell-h) = {
        if fill-mode {
          render-plot-deferred(
            (..spec, width: cell-w * 1cm, height: cell-h * 1cm),
            suppress-aesthetics: hoisted,
            tight-sides: tight-sides,
          ).content
        } else {
          let aspect-w = spec.width / 1cm
          let aspect-h = spec.height / 1cm
          let scale = calc.min(cell-w / aspect-w, cell-h / aspect-h)
          let inner = render-plot-deferred(
            (
              ..spec,
              width: aspect-w * scale * 1cm,
              height: aspect-h * scale * 1cm,
            ),
            suppress-aesthetics: hoisted,
            tight-sides: tight-sides,
          ).content
          box(
            width: cell-w * 1cm,
            height: cell-h * 1cm,
            align(center + horizon, inner),
          )
        }
      }

      let cells = ()
      for (i, spec) in panels.enumerate() {
        let col = calc.rem(i, cols)
        let row = calc.quo(i, cols)
        cells.push(render-cell(spec, col-tracks.at(col), row-tracks.at(row)))
      }

      if layout == "grid" {
        grid(columns: cols, gutter: gutter, ..cells)
      } else {
        stack(dir: direction, spacing: gutter, ..cells)
      }
    } else {
      if widths != none or heights != none {
        panic(
          "compose: `widths`/`heights` need a bounded `width`/`height`; set "
            + "them or wrap the composition in a sized box",
        )
      }
      let final-panels = if hoisted.len() == 0 {
        probes.map(p => p.content)
      } else {
        panels.map(spec => {
          render-plot-deferred(
            spec,
            suppress-aesthetics: hoisted,
            tight-sides: tight-sides,
          ).content
        })
      }
      if layout == "grid" {
        grid(columns: columns, gutter: gutter, ..final-panels)
      } else {
        stack(dir: direction, spacing: gutter, ..final-panels)
      }
    }

    if hoisted-guides.len() == 0 {
      return panel-block
    }

    let trained = probes.first().trained
    let legend-canvas = legend-mod.standalone(
      hoisted-guides,
      trained,
      theme,
      guides-placement,
      legend-size.width,
      legend-size.height,
    )
    let right-gap = right-gap-cm * 1cm

    if guides-placement == "right" {
      grid(
        columns: (auto, auto),
        align: horizon,
        gutter: right-gap,
        panel-block, legend-canvas,
      )
    } else if guides-placement == "left" {
      grid(
        columns: (auto, auto),
        align: horizon,
        legend-canvas, panel-block,
      )
    } else if guides-placement == "bottom" {
      stack(dir: ttb, panel-block, align(center, legend-canvas))
    } else {
      stack(dir: ttb, align(center, legend-canvas), panel-block)
    }
  })
}
