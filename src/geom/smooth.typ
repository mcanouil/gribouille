///! Smoothed trend line with optional confidence ribbon.
///!
///! v1 supports `method: "lm"` only (ordinary least squares, closed-form). The
///! underlying fit is computed by @stat-smooth, which also returns the
///! pointwise confidence band drawn when `se: true`.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-position
#import "../utils/types.typ": parse-number

/// Fitted trend line with an optional confidence ribbon.
///
/// Fits a smoother to `(x, y)` and draws the prediction as a line. When
/// `se` is `true`, the pointwise band is drawn underneath the line.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Falls back to the plot mapping when `none`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param method Smoother method. `"lm"` is the only supported value in v1.
/// @param se Whether to draw the confidence ribbon around the fit.
/// @param level Confidence level for the ribbon (e.g. `0.95`).
/// @param stroke Line thickness (a Typst length).
/// @param colour Fixed line colour. `auto` picks a neutral default.
/// @param fill Fixed ribbon fill. `auto` reuses the line colour.
/// @param alpha Ribbon opacity in `[0, 1]`.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 20).map(i => (
///   x: i,
///   y: i * 0.5 + calc.sin(i * 0.4) * 2,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 2pt),
///     geom-smooth(method: "lm"),
///   ),
/// )
/// ```
///
/// @see @stat-smooth, @geom-line, @geom-ribbon
#let geom-smooth(
  mapping: none,
  data: none,
  method: "lm",
  se: true,
  level: 0.95,
  stroke: 1pt,
  colour: auto,
  fill: auto,
  alpha: 0.2,
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "smooth",
  mapping: mapping,
  data: data,
  params: (method: method, se: se, level: level, stroke: stroke, colour: colour, fill: fill, alpha: alpha),
  stat: "smooth",
  position: "identity",
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none { return }
  let x-col = mapping.at("x", default: none)
  let y-col = mapping.at("y", default: none)
  if x-col == none or y-col == none { return }
  let x-trained = ctx.trained.at("x", default: none)
  let y-trained = ctx.trained.at("y", default: none)
  if x-trained == none or y-trained == none { return }

  let sorted = data.map(row => (
    x: parse-number(row.at(x-col, default: none)),
    y: parse-number(row.at(y-col, default: none)),
    lo: parse-number(row.at(mapping.at("ymin", default: ""), default: none)),
    hi: parse-number(row.at(mapping.at("ymax", default: ""), default: none)),
  )).filter(p => p.x != none and p.y != none).sorted(key: p => p.x)

  if sorted.len() < 2 { return }

  let base-colour = if layer.params.colour != auto and layer.params.colour != none {
    layer.params.colour
  } else {
    rgb("#3b5998")
  }

  // Confidence ribbon first, so the line draws on top.
  let has-band = layer.params.se and sorted.all(p => p.lo != none and p.hi != none)
  if has-band {
    let upper = sorted.map(p => (
      map-position(x-trained, p.x, ctx.px-range),
      map-position(y-trained, p.hi, ctx.py-range),
    ))
    let lower = sorted.rev().map(p => (
      map-position(x-trained, p.x, ctx.px-range),
      map-position(y-trained, p.lo, ctx.py-range),
    ))
    let pts = upper + lower
    if pts.all(p => p.at(0) != none and p.at(1) != none) {
      let fill-col = if layer.params.fill != auto and layer.params.fill != none {
        layer.params.fill
      } else { base-colour }
      let band = fill-col.transparentize((1 - layer.params.alpha) * 100%)
      cetz.draw.line(..pts, close: true, fill: band, stroke: none)
    }
  }

  let line-pts = sorted.map(p => (
    map-position(x-trained, p.x, ctx.px-range),
    map-position(y-trained, p.y, ctx.py-range),
  )).filter(p => p.at(0) != none and p.at(1) != none)
  if line-pts.len() >= 2 {
    cetz.draw.line(
      ..line-pts,
      stroke: (paint: base-colour, thickness: layer.params.stroke),
    )
  }
}
