///! Vertical bars taking heights directly from the y aesthetic.
///!
///! Use `geom-col` for pre-aggregated data; use @geom-bar when you want the
///! layer to count observations for you. The layer honours `position: "stack"`,
///! `"dodge"`, and `"fill"` via the matching position adjustments.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-position, map-continuous
#import "../utils/types.typ": parse-number

/// Bar layer with heights taken from the y aesthetic.
///
/// Each row becomes one bar centred at its x value. Use @geom-bar (stat-count)
/// when you want automatic counting; `geom-col` expects pre-aggregated y.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Falls back to the plot mapping when `none`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param width Bar width as a fraction of the category width (0 to 1).
/// @param fill Bar fill colour. `auto` resolves via the fill scale or a neutral default.
/// @param stroke Bar outline; `none` means no border.
/// @param alpha Bar opacity in `[0, 1]`.
/// @param stat Statistical transform name. Usually `"identity"`.
/// @param position Position adjustment: `"identity"`, `"stack"`, `"dodge"`, or `"fill"`.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
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
/// )
/// ```
///
/// @see @geom-bar, @position-stack, @position-dodge, @position-fill
#let geom-col(
  mapping: none,
  data: none,
  width: 0.9,
  fill: auto,
  stroke: none,
  alpha: 1,
  stat: "identity",
  position: "identity",
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "col",
  mapping: mapping,
  data: data,
  params: (width: width, fill: fill, stroke: stroke, alpha: alpha),
  stat: stat,
  position: position,
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none or mapping.x == none or mapping.y == none { return }
  let x-trained = ctx.trained.at("x", default: none)
  let y-trained = ctx.trained.at("y", default: none)
  if x-trained == none or y-trained == none { return }
  if y-trained.type != "continuous" { return }

  let position = layer.at("position", default: "identity")
  let ymin-col = mapping.at("ymin", default: none)
  let ymax-col = mapping.at("ymax", default: none)
  let use-minmax = (position == "stack" or position == "fill") and ymin-col != none and ymax-col != none

  let fill-col = mapping.at("fill", default: none)
  let fill-trained = ctx.trained.at("fill", default: none)
  let default-fill = if layer.params.fill != auto and layer.params.fill != none {
    layer.params.fill
  } else {
    rgb("#4c78a8")
  }

  let baseline-cy = map-continuous(
    calc.max(0.0, y-trained.domain.at(0)),
    y-trained.domain,
    ctx.py-range,
  )

  let (px-lo, px-hi) = ctx.px-range
  let category-width = if x-trained.type == "discrete" and x-trained.domain.len() > 0 {
    (px-hi - px-lo) / x-trained.domain.len()
  } else {
    // Continuous x: infer from minimum gap between unique values.
    let xs = data.map(r => parse-number(r.at(mapping.x, default: none))).filter(v => v != none)
    let (d-lo, d-hi) = x-trained.domain
    if xs.len() < 2 or d-hi == d-lo {
      (px-hi - px-lo) / 10
    } else {
      let sorted = xs.dedup().sorted()
      let gaps = range(sorted.len() - 1).map(i => sorted.at(i + 1) - sorted.at(i))
      let min-gap = calc.min(..gaps)
      min-gap * (px-hi - px-lo) / (d-hi - d-lo)
    }
  }
  let bar-width-fraction = layer.params.width
  let half = category-width * bar-width-fraction / 2

  for row in data {
    let cx = map-position(x-trained, row.at(mapping.x, default: none), ctx.px-range)
    if cx == none { continue }

    let (y-lo-cy, y-hi-cy) = if use-minmax {
      let lo-v = parse-number(row.at(ymin-col, default: none))
      let hi-v = parse-number(row.at(ymax-col, default: none))
      if lo-v == none or hi-v == none { continue }
      (
        map-continuous(lo-v, y-trained.domain, ctx.py-range),
        map-continuous(hi-v, y-trained.domain, ctx.py-range),
      )
    } else {
      let yv = parse-number(row.at(mapping.y, default: none))
      if yv == none { continue }
      let cy = map-continuous(yv, y-trained.domain, ctx.py-range)
      if cy >= baseline-cy { (baseline-cy, cy) } else { (cy, baseline-cy) }
    }

    let centre = cx
    let bar-half = half
    if position == "dodge" {
      let offset = row.at("_dodge-offset", default: 0)
      let n = row.at("_dodge-n", default: 1)
      centre = cx + offset * category-width * bar-width-fraction
      bar-half = (category-width * bar-width-fraction / n) / 2
    }

    let colour = if fill-col != none and fill-trained != none {
      (ctx.resolve-colour)(fill-trained, row.at(fill-col, default: none), ctx.palette)
    } else { default-fill }
    let alpha = layer.params.alpha
    let final-fill = if alpha < 1 { colour.transparentize((1 - alpha) * 100%) } else { colour }

    cetz.draw.rect(
      (centre - bar-half, y-lo-cy),
      (centre + bar-half, y-hi-cy),
      fill: final-fill,
      stroke: if layer.params.stroke == none { none } else { layer.params.stroke },
    )
  }
}
