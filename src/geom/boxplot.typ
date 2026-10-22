///! Boxplots from raw observations using \@stat-boxplot.
///!
///! The default `stat = "boxplot"` reduces each group to one summary row
///! before the geom draws. Pass `stat: "identity"` only when the layer
///! receives pre-computed summary rows (`x`, `lower`, `middle`, `upper`,
///! `ymin`, `ymax`, optional `outliers`).

#import "../deps.typ": cetz
#import "../layer.typ": make-layer, split-aes-params
#import "../position/apply.typ": layer-position-name
#import "../position/dodge.typ": dodge-centre, dodge-half
#import "../utils/aes-resolve.typ": resolve-channel
#import "../scale/train.typ": map-axis, map-position
#import "../utils/band.typ": axis-band
#import "../utils/radial.typ": (
  polar-canvas, radial-arc, radial-axis-ranges, radial-category-span,
  radial-wedge,
)
#import "../utils/flip.typ": range-axes, range-canvas-point, range-columns
#import "../utils/types.typ": parse-number
#import "../utils/stroke.typ": build-stroke
#import "../theme/theme.typ": (
  resolve-geom-colour, resolve-geom-defaults, resolve-geom-fill,
)

/// Boxplot layer: draws a Tukey box, whiskers, and outlier points per group.
///
/// Defaults to `stat = "boxplot"`, so the layer accepts raw observations and
/// computes the five-number summary per group internally. The default
/// `position = "identity"` keeps groups at their categorical x slot; switch
/// to `"dodge"` if you want side-by-side boxes per fill level.
///
/// \@category Geoms
/// \@subcategory Distributions
/// \@stability stable
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Falls back to the plot mapping when `none`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param width Box width in x data units. For discrete x this is also a data-unit width.
///
/// \@param colour Stroke colour for the box, median, and whiskers. `auto` falls back to the theme ink, since the outline carries the box's structure even when `fill` supplies the body colour.
///
/// \@param fill Box fill colour. `auto` resolves via the fill scale or a neutral default.
///
/// \@param stroke Stroke thickness for the box outline and whiskers.
///
/// \@param alpha Box opacity in `[0, 1]`.
///
/// \@param outlier-size Marker size for outlier points.
///
/// \@param outlier-colour Marker colour for outlier points. `auto` follows the box stroke colour.
///
/// \@param whisker-cap Cap length at the whisker ends as a fraction of `width`.
///
/// \@param stat Statistical transform name. `"boxplot"` by default.
///
/// \@param position Position adjustment name. `"identity"` by default.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Five-number summary computed per category from raw observations.
/// ```
/// //| alt: "Boxplots of y values across three categories (a, b, c) on the x axis showing Tukey box, median, and whiskers."
/// #let d = ()
/// #for grp in ("a", "b", "c") {
///   for i in range(20) {
///     d.push((grp: grp, y: calc.sin(i) + i / 10))
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y"),
///   layers: (geom-boxplot(),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Add a second mapping (`fill`) and switch `position` to
/// `"dodge"` to compare distributions side by side per group.
/// ```
/// //| alt: "Dodged boxplots of y across three groups (a, b, c) on the x axis with two fill categories (x, y) side by side."
/// #let d = ()
/// #for grp in ("a", "b", "c") {
///   for k in ("x", "y") {
///     for i in range(20) {
///       d.push((grp: grp, k: k, y: calc.sin(i) + i / 10 + (if k == "y" { 0.7 } else { 0 })))
///     }
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "k"),
///   layers: (geom-boxplot(position: "dodge"),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@stat-boxplot, \@geom-col
#let geom-boxplot(
  mapping: none,
  data: none,
  width: 0.6,
  colour: auto,
  fill: auto,
  stroke: 0.6pt,
  alpha: auto,
  outlier-size: 1.8pt,
  outlier-colour: auto,
  whisker-cap: 0.5,
  stat: "boxplot",
  position: "identity",
  key: auto,
  inherit-aes: true,
  ..args,
) = make-layer(
  "boxplot",
  mapping: mapping,
  data: data,
  params: (
    width: width,
    colour: colour,
    fill: fill,
    stroke: stroke,
    alpha: alpha,
    outlier-size: outlier-size,
    outlier-colour: outlier-colour,
    whisker-cap: whisker-cap,
  )
    + split-aes-params("geom-boxplot", args),
  stat: stat,
  position: position,
  key: key,
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none { return }
  let flipped = ctx.at("flipped", default: false)
  let cols = range-columns(mapping, flipped)
  let lower-col = mapping.at("lower", default: none)
  let middle-col = mapping.at("middle", default: none)
  let upper-col = mapping.at("upper", default: none)
  if (
    cols.pos == none
      or lower-col == none
      or middle-col == none
      or upper-col == none
      or cols.min == none
      or cols.max == none
  ) { return }

  let axes = range-axes(ctx)
  if axes == none { return }

  let g-defaults = resolve-geom-defaults(ctx.theme)
  // Box outline, median, and whiskers carry the boxplot's structure, so
  // the stroke default always stands even when fill is mapped or pinned.
  let default-colour = resolve-geom-colour(g-defaults)
  let default-fill = resolve-geom-fill(g-defaults, role: "paper")
  let outlier-colour-param = layer.params.outlier-colour
  let outlier-paint-of(resolved-stroke) = if outlier-colour-param != auto {
    outlier-colour-param
  } else { resolved-stroke }
  let stroke-thickness = layer.params.stroke
  let half-width = layer.params.width / 2
  let cap-half = half-width * layer.params.whisker-cap

  let radial = ctx.at("radial", default: none)
  if radial != none {
    let x-trained = axes.pos-trained
    let y-trained = axes.value-trained
    let cat-trained = if radial.cat-is-theta { x-trained } else { y-trained }
    let val-trained = if radial.cat-is-theta { y-trained } else { x-trained }
    if val-trained.type != "continuous" { return }
    let cat-col = if radial.cat-is-theta { cols.pos } else {
      mapping.at("y", default: none)
    }
    let (cat-range, value-range) = radial-axis-ranges(radial)
    let half = (
      radial-category-span(cat-trained, cat-col, cat-range, data)
        * layer.params.width
        / 2
    )
    let cap-half-cat = half * layer.params.whisker-cap
    for row in data {
      let raw-cat = row.at(cat-col, default: none)
      let cat-c = map-position(cat-trained, raw-cat, cat-range)
      let lower = parse-number(row.at(lower-col, default: none))
      let middle = parse-number(row.at(middle-col, default: none))
      let upper = parse-number(row.at(upper-col, default: none))
      let ymin = parse-number(row.at(cols.min, default: none))
      let ymax = parse-number(row.at(cols.max, default: none))
      if (
        cat-c == none
          or lower == none
          or middle == none
          or upper == none
          or ymin == none
          or ymax == none
      ) { continue }
      let whisker-lo = parse-number(row.at("whisker-lo", default: none))
      let whisker-hi = parse-number(row.at("whisker-hi", default: none))
      if whisker-lo == none { whisker-lo = ymin }
      if whisker-hi == none { whisker-hi = ymax }
      let v-lower = map-axis(val-trained, lower, value-range)
      let v-middle = map-axis(val-trained, middle, value-range)
      let v-upper = map-axis(val-trained, upper, value-range)
      let v-wlo = map-axis(val-trained, whisker-lo, value-range)
      let v-whi = map-axis(val-trained, whisker-hi, value-range)

      let final-fill = resolve-channel(
        "fill",
        layer.params,
        mapping,
        ctx,
        row,
        default-fill,
      )
      let resolved-stroke = resolve-channel(
        "colour",
        layer.params,
        mapping,
        ctx,
        row,
        default-colour,
      )
      let stroke-spec = build-stroke(stroke-thickness, resolved-stroke)

      if radial.cat-is-theta {
        let theta-lo = cat-c - half
        let theta-hi = cat-c + half
        let cap-lo = cat-c - cap-half-cat
        let cap-hi = cat-c + cap-half-cat
        let (r-lower, r-upper) = if v-lower <= v-upper {
          (v-lower, v-upper)
        } else { (v-upper, v-lower) }
        let pts = radial-wedge(theta-lo, theta-hi, r-lower, r-upper, radial)
        cetz.draw.line(
          ..pts,
          close: true,
          fill: final-fill,
          stroke: stroke-spec,
        )
        let median-pts = radial-arc(theta-lo, theta-hi, v-middle, radial)
        cetz.draw.line(..median-pts, stroke: stroke-spec)
        cetz.draw.line(
          polar-canvas(radial, cat-c, v-wlo),
          polar-canvas(radial, cat-c, r-lower),
          stroke: stroke-spec,
        )
        cetz.draw.line(
          polar-canvas(radial, cat-c, r-upper),
          polar-canvas(radial, cat-c, v-whi),
          stroke: stroke-spec,
        )
        if layer.params.whisker-cap > 0 {
          let cap-lo-pts = radial-arc(cap-lo, cap-hi, v-wlo, radial)
          let cap-hi-pts = radial-arc(cap-lo, cap-hi, v-whi, radial)
          cetz.draw.line(..cap-lo-pts, stroke: stroke-spec)
          cetz.draw.line(..cap-hi-pts, stroke: stroke-spec)
        }
        let outlier-paint = outlier-paint-of(resolved-stroke)
        let outliers = row.at("outliers", default: ())
        for ov in outliers {
          let v = parse-number(ov)
          if v == none { continue }
          let r = map-axis(val-trained, v, value-range)
          cetz.draw.circle(
            polar-canvas(radial, cat-c, r),
            radius: layer.params.outlier-size,
            fill: outlier-paint,
            stroke: none,
          )
        }
      } else {
        // Theta-axis carries values: box wedge spans the theta range, with
        // category along radial. Whiskers run as arcs at constant r-mid.
        let r-lo = cat-c - half
        let r-hi = cat-c + half
        let cap-rlo = cat-c - cap-half-cat
        let cap-rhi = cat-c + cap-half-cat
        let pts = radial-wedge(v-lower, v-upper, r-lo, r-hi, radial)
        cetz.draw.line(
          ..pts,
          close: true,
          fill: final-fill,
          stroke: stroke-spec,
        )
        cetz.draw.line(
          polar-canvas(radial, v-middle, r-lo),
          polar-canvas(radial, v-middle, r-hi),
          stroke: stroke-spec,
        )
        let whisker-lo-pts = radial-arc(v-wlo, v-lower, cat-c, radial)
        let whisker-hi-pts = radial-arc(v-upper, v-whi, cat-c, radial)
        cetz.draw.line(..whisker-lo-pts, stroke: stroke-spec)
        cetz.draw.line(..whisker-hi-pts, stroke: stroke-spec)
        if layer.params.whisker-cap > 0 {
          cetz.draw.line(
            polar-canvas(radial, v-wlo, cap-rlo),
            polar-canvas(radial, v-wlo, cap-rhi),
            stroke: stroke-spec,
          )
          cetz.draw.line(
            polar-canvas(radial, v-whi, cap-rlo),
            polar-canvas(radial, v-whi, cap-rhi),
            stroke: stroke-spec,
          )
        }
        let outlier-paint = outlier-paint-of(resolved-stroke)
        let outliers = row.at("outliers", default: ())
        for ov in outliers {
          let v = parse-number(ov)
          if v == none { continue }
          let theta = map-axis(val-trained, v, value-range)
          cetz.draw.circle(
            polar-canvas(radial, theta, cat-c),
            radius: layer.params.outlier-size,
            fill: outlier-paint,
            stroke: none,
          )
        }
      }
    }
    return
  }

  if axes.value-trained.type != "continuous" { return }

  let position-name = layer-position-name(layer)
  let pt = range-canvas-point.with(flipped)

  for row in data {
    let raw-pos = row.at(cols.pos, default: none)
    let pos-c = map-position(axes.pos-trained, raw-pos, axes.pos-range)
    if pos-c == none { continue }

    let lower = parse-number(row.at(lower-col, default: none))
    let middle = parse-number(row.at(middle-col, default: none))
    let upper = parse-number(row.at(upper-col, default: none))
    let ymin = parse-number(row.at(cols.min, default: none))
    let ymax = parse-number(row.at(cols.max, default: none))
    if (
      lower == none
        or middle == none
        or upper == none
        or ymin == none
        or ymax == none
    ) { continue }

    // Whisker endpoints come from explicit fields when stat-boxplot supplies
    // them; otherwise we fall back to ymin/ymax (identity stat with
    // pre-computed summaries that omit outlier extremes).
    let whisker-lo = parse-number(row.at("whisker-lo", default: none))
    let whisker-hi = parse-number(row.at("whisker-hi", default: none))
    if whisker-lo == none { whisker-lo = ymin }
    if whisker-hi == none { whisker-hi = ymax }

    let (value-trained, value-range) = (axes.value-trained, axes.value-range)
    let v-lower = map-axis(value-trained, lower, value-range)
    let v-middle = map-axis(value-trained, middle, value-range)
    let v-upper = map-axis(value-trained, upper, value-range)
    let v-whisker-lo = map-axis(value-trained, whisker-lo, value-range)
    let v-whisker-hi = map-axis(value-trained, whisker-hi, value-range)

    let box-band = axis-band(
      axes.pos-trained,
      raw-pos,
      half-width,
      axes.pos-range,
    )
    let cap-band = axis-band(
      axes.pos-trained,
      raw-pos,
      cap-half,
      axes.pos-range,
    )
    if box-band == none or cap-band == none { continue }
    let (pos-lo, pos-hi) = box-band
    let (cap-lo, cap-hi) = cap-band

    let centre = pos-c
    if position-name == "dodge" {
      let span = pos-hi - pos-lo
      centre = dodge-centre(row, pos-c, span)
      let box-half = dodge-half(row, span / 2)
      let cap-half-shrunk = dodge-half(row, (cap-hi - cap-lo) / 2)
      pos-lo = centre - box-half
      pos-hi = centre + box-half
      cap-lo = centre - cap-half-shrunk
      cap-hi = centre + cap-half-shrunk
    }

    let final-fill = resolve-channel(
      "fill",
      layer.params,
      mapping,
      ctx,
      row,
      default-fill,
    )
    let resolved-stroke = resolve-channel(
      "colour",
      layer.params,
      mapping,
      ctx,
      row,
      default-colour,
    )
    let stroke-spec = build-stroke(stroke-thickness, resolved-stroke)

    cetz.draw.rect(
      pt(pos-lo, v-lower),
      pt(pos-hi, v-upper),
      fill: final-fill,
      stroke: stroke-spec,
    )

    cetz.draw.line(
      pt(pos-lo, v-middle),
      pt(pos-hi, v-middle),
      stroke: stroke-spec,
    )

    cetz.draw.line(
      pt(centre, v-whisker-lo),
      pt(centre, v-lower),
      stroke: stroke-spec,
    )
    cetz.draw.line(
      pt(centre, v-upper),
      pt(centre, v-whisker-hi),
      stroke: stroke-spec,
    )

    if layer.params.whisker-cap > 0 {
      cetz.draw.line(
        pt(cap-lo, v-whisker-lo),
        pt(cap-hi, v-whisker-lo),
        stroke: stroke-spec,
      )
      cetz.draw.line(
        pt(cap-lo, v-whisker-hi),
        pt(cap-hi, v-whisker-hi),
        stroke: stroke-spec,
      )
    }

    let outlier-paint = outlier-paint-of(resolved-stroke)
    let outliers = row.at("outliers", default: ())
    for ov in outliers {
      let v = parse-number(ov)
      if v == none { continue }
      cetz.draw.circle(
        pt(centre, map-axis(value-trained, v, value-range)),
        radius: layer.params.outlier-size,
        fill: outlier-paint,
        stroke: none,
      )
    }
  }
}
