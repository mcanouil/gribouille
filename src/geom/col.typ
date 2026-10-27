///! Vertical bars taking heights directly from the y aesthetic.
///!
///! Use `geom-col` for pre-aggregated data; use \@geom-bar when you want the
///! layer to count observations for you. The layer honours `position: "stack"`,
///! `"dodge"`, and `"fill"` via the matching position adjustments.

#import "../deps.typ": cetz
#import "../layer.typ": make-layer, split-aes-params
#import "../position/apply.typ": layer-marks-abut, layer-position-name
#import "../position/dodge.typ": dodge-centre, dodge-geometry, dodge-half
#import "../utils/aes-resolve.typ": resolve-channel
#import "../coord/project.typ": axis-mapper
#import "../scale/train.typ": discrete-slot-width, mapping-ref-col
#import "../utils/bin.typ": bin-half-width
#import "../utils/flip.typ": user-axes, user-axis-key, user-columns, user-point
#import "../utils/types.typ": parse-number
#import "../utils/aes-pair.typ": resolve-pair-defaults
#import "../utils/radial.typ": (
  radial-category-span, radial-mappers, radial-wedge,
)
#import "../utils/stroke.typ": resolve-stroke-spec, seal-seam
#import "../theme/theme.typ": (
  resolve-geom-colour, resolve-geom-defaults, resolve-geom-fill,
  resolve-geom-linewidth,
)

// Outer edges of the bars on a continuous `x` axis. A bar spans
// `width` times the smallest gap between distinct `x` values, the same rule
// as `draw`, and rows from stat-bin also widen `x` by half a bin. `none`
// when the layer has no numeric `x` or nothing to pad.
#let _extents(params, mapping, data) = {
  let none-ext = (x: none, y: none)
  let x-col = mapping-ref-col(mapping.at("x", default: none))
  if x-col == none { return none-ext }
  // Sorted first, then walked: duplicates sit side by side as a zero gap,
  // which is skipped, so no `dedup` pass is needed.
  let xs = data
    .map(r => parse-number(r.at(x-col, default: none)))
    .filter(v => v != none)
    .sorted()
  if xs.len() == 0 { return none-ext }
  let min-gap = none
  for i in range(xs.len() - 1) {
    let gap = xs.at(i + 1) - xs.at(i)
    if gap == 0 { continue }
    if min-gap == none or gap < min-gap { min-gap = gap }
  }
  let bar-half = if min-gap == none { 0.0 } else {
    min-gap * params.at("width", default: 0.9) / 2
  }
  let bin-half = bin-half-width(data)
  if bar-half <= 0 and bin-half <= 0 { return none-ext }
  (
    x: (xs.first() - bin-half - bar-half, xs.last() + bin-half + bar-half),
    y: none,
  )
}

#let spec = (
  reads: ("x", "y", "ymin", "ymax", "colour", "fill", "alpha", "stroke"),
  extents: _extents,
)

/// Bar layer with heights taken from the y aesthetic.
///
/// Each row becomes one bar centred at its x value. Use \@geom-bar (stat-count)
/// when you want automatic counting; `geom-col` expects pre-aggregated y.
///
/// \@category Geoms
/// \@subcategory Bars and histograms
/// \@stability stable
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Falls back to the plot mapping when `none`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param width Bar width as a fraction of the category width (0 to 1).
///
/// \@param colour Bar outline colour. `auto` resolves via the colour scale, falling back to the theme `ink` only when neither `colour` nor `fill` is set.
///
/// \@param fill Bar fill colour. `auto` resolves via the fill scale or a neutral default.
///
/// \@param stroke Bar outline thickness (a Typst length) or stroke dictionary; `none` disables the outline.
///
/// \@param alpha Bar opacity in `[0, 1]`.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param stat Statistical transform name. Usually `"identity"`.
///
/// \@param position Position adjustment: `"identity"`, `"stack"`, `"dodge"`, or `"fill"`.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Pre-aggregated heights drawn one bar per row.
/// ```
/// //| alt: "Bar chart of revenue by quarter (Q1 through Q4) on the x axis with heights taken directly from the y aesthetic."
/// #let d = (
///   (q: "Q1", revenue: 10),
///   (q: "Q2", revenue: 18),
///   (q: "Q3", revenue: 25),
///   (q: "Q4", revenue: 22),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "q", y: "revenue"),
///   layers: (geom-col(),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Adding a `fill` mapping with `position: "stack"` (default for
/// stacked) accumulates contributions per category.
/// ```
/// //| alt: "Stacked bar chart of revenue per quarter with EU and US regions accumulated by fill aesthetic in each bar."
/// #let d = (
///   (q: "Q1", revenue: 6, region: "EU"),
///   (q: "Q1", revenue: 4, region: "US"),
///   (q: "Q2", revenue: 9, region: "EU"),
///   (q: "Q2", revenue: 9, region: "US"),
///   (q: "Q3", revenue: 14, region: "EU"),
///   (q: "Q3", revenue: 11, region: "US"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "q", y: "revenue", fill: "region"),
///   layers: (geom-col(position: "stack"),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@geom-bar, \@position-stack, \@position-dodge, \@position-fill
#let geom-col(
  mapping: none,
  data: none,
  width: 0.9,
  colour: auto,
  fill: auto,
  stroke: none,
  alpha: auto,
  key: auto,
  stat: "identity",
  position: "identity",
  inherit-aes: true,
  ..args,
) = make-layer(
  "col",
  mapping: mapping,
  data: data,
  params: (
    width: width,
    colour: colour,
    fill: fill,
    stroke: stroke,
    alpha: alpha,
  )
    + split-aes-params("geom-col", args, spec.reads),
  key: key,
  stat: stat,
  position: position,
  inherit-aes: inherit-aes,
)

#let _draw-radial(layer, ctx, mapping, data, radial) = {
  let cat-trained = ctx.trained.at("x", default: none)
  let value-trained = ctx.trained.at("y", default: none)
  if cat-trained == none or value-trained == none { return }
  if value-trained.type != "continuous" { return }

  let cat-col = mapping.x
  let value-col = mapping.y
  let position = layer-position-name(layer)
  let dodge = dodge-geometry(ctx, layer)
  // Only stacked segments share an edge; a bar that stands on its own would
  // lose part of its category gap to the seal.
  let abutting = layer-marks-abut(layer)
  let vmin-col = mapping.at("ymin", default: none)
  let vmax-col = mapping.at("ymax", default: none)
  let use-minmax = (
    (position == "stack" or position == "fill")
      and vmin-col != none
      and vmax-col != none
  )

  let g-defaults = resolve-geom-defaults(ctx.theme)
  let default-thickness = resolve-geom-linewidth(g-defaults)
  let (default-colour, default-fill) = resolve-pair-defaults(
    layer,
    mapping,
    resolve-geom-colour(g-defaults, role: none),
    resolve-geom-fill(g-defaults, role: "tint"),
  )

  let baseline = calc.max(0.0, value-trained.domain.at(0))
  let bar-width-fraction = layer.params.width

  let (cat: map-cat, value: map-value) = radial-mappers(ctx)
  let category-span = radial-category-span(ctx, cat-col, data)
  let half = category-span * bar-width-fraction / 2

  for row in data {
    let cat-c = map-cat(row.at(cat-col, default: none))
    if cat-c == none { continue }

    let (v-lo, v-hi) = if use-minmax {
      let lo-v = parse-number(row.at(vmin-col, default: none))
      let hi-v = parse-number(row.at(vmax-col, default: none))
      if lo-v == none or hi-v == none { continue }
      (map-value(lo-v), map-value(hi-v))
    } else {
      let raw = parse-number(row.at(value-col, default: none))
      if raw == none { continue }
      (map-value(baseline), map-value(raw))
    }

    let final-fill = resolve-channel(
      "fill",
      layer.params,
      mapping,
      ctx,
      row,
      default-fill,
    )
    let stroke-spec = resolve-stroke-spec(
      layer.params,
      mapping,
      ctx,
      row,
      default-colour,
      default-thickness: default-thickness,
    )

    let centre = cat-c
    let bar-half = half
    if position == "dodge" {
      centre = dodge-centre(dodge, row, cat-c, 2 * half)
      bar-half = dodge-half(row, half)
    }

    let (theta-lo, theta-hi, r-lo, r-hi) = if radial.cat-is-theta {
      (centre - bar-half, centre + bar-half, v-lo, v-hi)
    } else {
      (v-lo, v-hi, centre - bar-half, centre + bar-half)
    }
    if r-lo > r-hi { (r-lo, r-hi) = (r-hi, r-lo) }

    let pts = radial-wedge(theta-lo, theta-hi, r-lo, r-hi, radial)
    cetz.draw.line(
      ..pts,
      close: true,
      fill: final-fill,
      stroke: seal-seam(stroke-spec, final-fill, abutting: abutting),
    )
  }
}

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none or mapping.x == none or mapping.y == none { return }
  let axes = user-axes(ctx)
  if axes == none { return }

  let radial = ctx.at("radial", default: none)
  if radial != none {
    _draw-radial(layer, ctx, mapping, data, radial)
    return
  }

  // The value axis is the user's y and the category axis the user's x, which
  // the flip swap moves onto the other canvas axes.
  let value-trained = axes.y-trained
  let cat-trained = axes.x-trained
  let columns = user-columns(mapping, ctx)
  let value-col = columns.y
  let cat-col = columns.x
  let cat-range = axes.x-range
  if value-trained.type != "continuous" { return }

  let position = layer-position-name(layer)
  let dodge = dodge-geometry(ctx, layer)
  // Only stacked segments share an edge; a bar that stands on its own would
  // lose part of its category gap to the seal.
  let abutting = layer-marks-abut(layer)
  // Stacked/filled bars receive ymin/ymax from the position adjustment under
  // either orientation; the position writes them under the y keys, and under
  // flip the renderer's mapping swap routes them onto x.
  let vmin-col = columns.ymin
  let vmax-col = columns.ymax
  let use-minmax = (
    (position == "stack" or position == "fill")
      and vmin-col != none
      and vmax-col != none
  )

  let g-defaults = resolve-geom-defaults(ctx.theme)
  let default-thickness = resolve-geom-linewidth(g-defaults)
  let (default-colour, default-fill) = resolve-pair-defaults(
    layer,
    mapping,
    resolve-geom-colour(g-defaults, role: none),
    resolve-geom-fill(g-defaults, role: "tint"),
  )

  let map-cat = axis-mapper(ctx, user-axis-key("x", ctx))
  let map-cat-stat = axis-mapper(ctx, user-axis-key("x", ctx), space: "stat")
  let map-value = axis-mapper(
    ctx,
    user-axis-key("y", ctx),
    space: "stat",
  )
  let baseline-vc = map-value(calc.max(0.0, value-trained.domain.at(0)))

  let (cat-lo, cat-hi) = cat-range
  let category-span = if (
    cat-trained.type == "discrete" and cat-trained.domain.len() > 0
  ) {
    discrete-slot-width(cat-trained, cat-range)
  } else {
    // Continuous category axis: infer from minimum gap between unique values.
    let xs = data
      .map(r => parse-number(r.at(cat-col, default: none)))
      .filter(v => v != none)
    let (d-lo, d-hi) = cat-trained.domain
    let sorted = xs.dedup().sorted()
    if sorted.len() < 2 or d-hi == d-lo {
      (cat-hi - cat-lo) / 10
    } else {
      let panel-gaps = range(sorted.len() - 1).map(i => calc.abs(
        map-cat-stat(sorted.at(i + 1)) - map-cat-stat(sorted.at(i)),
      ))
      calc.min(..panel-gaps)
    }
  }
  let bar-width-fraction = layer.params.width
  let half = category-span * bar-width-fraction / 2

  for row in data {
    let cat-c = map-cat(row.at(cat-col, default: none))
    if cat-c == none { continue }

    let (v-lo-c, v-hi-c) = if use-minmax {
      let lo-v = parse-number(row.at(vmin-col, default: none))
      let hi-v = parse-number(row.at(vmax-col, default: none))
      if lo-v == none or hi-v == none { continue }
      (map-value(lo-v), map-value(hi-v))
    } else {
      let raw = parse-number(row.at(value-col, default: none))
      if raw == none { continue }
      let vc = map-value(raw)
      if vc >= baseline-vc { (baseline-vc, vc) } else { (vc, baseline-vc) }
    }

    let centre = cat-c
    let bar-half = half
    if position == "dodge" {
      let bucket = category-span * bar-width-fraction
      centre = dodge-centre(dodge, row, cat-c, bucket)
      bar-half = dodge-half(row, bucket / 2)
    }

    let final-fill = resolve-channel(
      "fill",
      layer.params,
      mapping,
      ctx,
      row,
      default-fill,
    )
    let stroke-spec = resolve-stroke-spec(
      layer.params,
      mapping,
      ctx,
      row,
      default-colour,
      default-thickness: default-thickness,
    )

    let a = user-point(ctx, centre - bar-half, v-lo-c)
    let b = user-point(ctx, centre + bar-half, v-hi-c)

    cetz.draw.rect(
      a,
      b,
      fill: final-fill,
      stroke: seal-seam(stroke-spec, final-fill, abutting: abutting),
    )
  }
}
