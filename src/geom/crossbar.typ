///! Hollow box from `ymin` to `ymax` with a thicker bar at `y` (the median).

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

/// Crossbar layer: a box from `ymin` to `ymax` with a horizontal bar at `y`.
///
/// Mapping must provide `x`, `y`, `ymin`, `ymax`. The `width` parameter sets
/// the box width in x data units for continuous x, and as a fraction of the
/// per-category slot width for discrete x.
///
/// \@category Geoms
/// \@subcategory Intervals and errors
/// \@stability stable
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Must map `x`, `y`, `ymin`, `ymax`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param width Box width. In x data units for continuous x; a fraction of the slot width for discrete x.
///
/// \@param colour Stroke colour for the box and the median bar. `auto` falls back to the theme ink, since the outline and median carry the crossbar's structure even when `fill` supplies the body colour.
///
/// \@param fill Box fill colour. `auto` resolves via the fill scale or a neutral default.
///
/// \@param stroke Stroke thickness for the box outline.
///
/// \@param middle-stroke Stroke thickness for the median bar.
///
/// \@param alpha Box opacity in `[0, 1]`.
///
/// \@param stat Statistical transform name. Usually `"identity"`.
///
/// \@param position Position adjustment name. Defaults to `"identity"`; use `"dodge"` to place groups side by side per fill level.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Box from `lo` to `hi` with the median bar at `y`.
/// ```
/// //| alt: "Crossbars at x = 1 to 4 with hollow boxes spanning lo to hi and a thick median bar at y for each row."
/// #let d = range(1, 5).map(i => (
///   x: i,
///   y: i,
///   lo: i - 0.6,
///   hi: i + 0.6,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: as-factor("x"), y: "y", ymin: "lo", ymax: "hi"),
///   layers: (geom-crossbar(),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Map `fill` to a categorical column to colour the box per group.
/// ```
/// //| alt: "Crossbars across x = 1 to 4 with boxes coloured by even/odd category via the fill aesthetic."
/// #let d = range(1, 5).map(i => (
///   x: i, y: i, lo: i - 0.6, hi: i + 0.6,
///   k: if calc.rem(i, 2) == 0 { "even" } else { "odd" },
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: as-factor("x"), y: "y", ymin: "lo", ymax: "hi", fill: "k"),
///   layers: (geom-crossbar(alpha: 0.6),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@geom-errorbar, \@geom-pointrange, \@geom-boxplot
#let geom-crossbar(
  mapping: none,
  data: none,
  width: 0.6,
  colour: auto,
  fill: auto,
  stroke: 0.6pt,
  middle-stroke: 1.2pt,
  alpha: auto,
  stat: "identity",
  position: "identity",
  key: auto,
  inherit-aes: true,
  ..args,
) = make-layer(
  "crossbar",
  mapping: mapping,
  data: data,
  params: (
    width: width,
    colour: colour,
    fill: fill,
    stroke: stroke,
    middle-stroke: middle-stroke,
    alpha: alpha,
  )
    + split-aes-params("geom-crossbar", args),
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
  if (
    cols.pos == none
      or cols.value == none
      or cols.min == none
      or cols.max == none
  ) { return }
  let axes = range-axes(ctx)
  if axes == none { return }

  let g-defaults = resolve-geom-defaults(ctx.theme)
  // Box outline and median bar carry the crossbar's structure, so the
  // stroke default always stands even when fill is mapped or pinned.
  let default-colour = resolve-geom-colour(g-defaults)
  let default-fill = resolve-geom-fill(g-defaults, role: "paper")

  let half-width = layer.params.width / 2
  let position-name = layer-position-name(layer)

  let radial = ctx.at("radial", default: none)
  if radial != none {
    let x-trained = axes.pos-trained
    let y-trained = axes.value-trained
    let cat-trained = if radial.cat-is-theta { x-trained } else { y-trained }
    let val-trained = if radial.cat-is-theta { y-trained } else { x-trained }
    let cat-col = if radial.cat-is-theta { cols.pos } else { cols.value }
    let (cat-range, value-range) = radial-axis-ranges(radial)
    let half = (
      radial-category-span(cat-trained, cat-col, cat-range, data)
        * layer.params.width
        / 2
    )
    for row in data {
      let raw-cat = row.at(cat-col, default: none)
      let cat-c = map-position(cat-trained, raw-cat, cat-range)
      let mid = parse-number(row.at(cols.value, default: none))
      let lo = parse-number(row.at(cols.min, default: none))
      let hi = parse-number(row.at(cols.max, default: none))
      if cat-c == none or mid == none or lo == none or hi == none { continue }
      let v-mid = map-axis(val-trained, mid, value-range)
      let v-lo = map-axis(val-trained, lo, value-range)
      let v-hi = map-axis(val-trained, hi, value-range)
      let (theta-lo, theta-hi, r-lo, r-hi, r-mid) = if radial.cat-is-theta {
        (cat-c - half, cat-c + half, v-lo, v-hi, v-mid)
      } else {
        (v-lo, v-hi, cat-c - half, cat-c + half, cat-c)
      }
      if r-lo > r-hi { (r-lo, r-hi) = (r-hi, r-lo) }

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
      let stroke-spec = build-stroke(layer.params.stroke, resolved-stroke)
      let middle-stroke-spec = build-stroke(
        layer.params.middle-stroke,
        resolved-stroke,
      )

      let pts = radial-wedge(theta-lo, theta-hi, r-lo, r-hi, radial)
      cetz.draw.line(
        ..pts,
        close: true,
        fill: final-fill,
        stroke: stroke-spec,
      )
      if radial.cat-is-theta {
        let median = radial-arc(theta-lo, theta-hi, r-mid, radial)
        cetz.draw.line(..median, stroke: middle-stroke-spec)
      } else {
        cetz.draw.line(
          polar-canvas(radial, v-mid, r-lo),
          polar-canvas(radial, v-mid, r-hi),
          stroke: middle-stroke-spec,
        )
      }
    }
    return
  }

  for row in data {
    let raw-pos = row.at(cols.pos, default: none)
    let pos-c = map-position(axes.pos-trained, raw-pos, axes.pos-range)
    let mid = parse-number(row.at(cols.value, default: none))
    let lo = parse-number(row.at(cols.min, default: none))
    let hi = parse-number(row.at(cols.max, default: none))
    if pos-c == none or mid == none or lo == none or hi == none { continue }
    let v-mid = map-position(axes.value-trained, mid, axes.value-range)
    let v-lo = map-position(axes.value-trained, lo, axes.value-range)
    let v-hi = map-position(axes.value-trained, hi, axes.value-range)
    if v-mid == none or v-lo == none or v-hi == none { continue }

    let band = axis-band(
      axes.pos-trained,
      raw-pos,
      half-width,
      axes.pos-range,
    )
    let (pos-lo, pos-hi) = if band == none { (pos-c, pos-c) } else { band }

    if position-name == "dodge" {
      let span = pos-hi - pos-lo
      let centre = dodge-centre(row, pos-c, span)
      let half = dodge-half(row, span / 2)
      pos-lo = centre - half
      pos-hi = centre + half
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
    let stroke-spec = build-stroke(layer.params.stroke, resolved-stroke)
    let middle-stroke-spec = build-stroke(
      layer.params.middle-stroke,
      resolved-stroke,
    )

    cetz.draw.rect(
      range-canvas-point(flipped, pos-lo, v-lo),
      range-canvas-point(flipped, pos-hi, v-hi),
      fill: final-fill,
      stroke: stroke-spec,
    )
    cetz.draw.line(
      range-canvas-point(flipped, pos-lo, v-mid),
      range-canvas-point(flipped, pos-hi, v-mid),
      stroke: middle-stroke-spec,
    )
  }
}
