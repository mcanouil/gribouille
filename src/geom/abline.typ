///! Oblique reference line from slope and intercept.
///!
///! Requires continuous x and y scales. The line is drawn across the full
///! trained x domain using `y = slope * x + intercept`.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-continuous

/// Straight reference line described by slope and intercept.
///
/// The line runs across the full trained x domain. Requires continuous x
/// and y scales; discrete scales are skipped silently.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param slope Line slope.
/// @param intercept Line y intercept.
/// @param colour Line colour.
/// @param stroke Line thickness (a Typst length).
/// @param alpha Line opacity in `[0, 1]`.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping. Defaults to `false`.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i + calc.rem(i, 2)))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 2pt),
///     geom-abline(slope: 1, intercept: 0, colour: rgb("#cc0000")),
///   ),
/// )
/// ```
///
/// @see @geom-hline, @geom-vline, @geom-smooth
#let geom-abline(
  slope: 1,
  intercept: 0,
  colour: rgb("#888888"),
  stroke: 0.6pt,
  alpha: 1,
  inherit-aes: false,
) = (
  kind: "layer",
  geom: "abline",
  mapping: none,
  data: none,
  params: (
    slope: slope,
    intercept: intercept,
    colour: colour,
    stroke: stroke,
    alpha: alpha,
  ),
  stat: "identity",
  position: "identity",
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let x-trained = ctx.trained.at("x", default: none)
  let y-trained = ctx.trained.at("y", default: none)
  if x-trained == none or y-trained == none { return }
  if x-trained.type != "continuous" or y-trained.type != "continuous" { return }
  let (x-lo, x-hi) = x-trained.domain
  let slope = float(layer.params.slope)
  let intercept = float(layer.params.intercept)
  let y-lo = slope * x-lo + intercept
  let y-hi = slope * x-hi + intercept
  let cx-lo = map-continuous(x-lo, x-trained.domain, ctx.px-range)
  let cx-hi = map-continuous(x-hi, x-trained.domain, ctx.px-range)
  let cy-lo = map-continuous(y-lo, y-trained.domain, ctx.py-range)
  let cy-hi = map-continuous(y-hi, y-trained.domain, ctx.py-range)
  let colour = layer.params.colour
  let fill = if layer.params.alpha < 1 {
    colour.transparentize((1 - layer.params.alpha) * 100%)
  } else { colour }
  cetz.draw.line(
    (cx-lo, cy-lo),
    (cx-hi, cy-hi),
    stroke: (paint: fill, thickness: layer.params.stroke),
  )
}
