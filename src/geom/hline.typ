///! Horizontal reference line(s) at given y intercepts.
///!
///! Works only with a continuous y scale. `yintercept` accepts a single value
///! or an array for drawing multiple reference lines at once.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-continuous

/// Horizontal reference line at one or more y intercepts.
///
/// `yintercept` can be a scalar or an array. The layer does not inherit the
/// plot mapping by default; it draws purely from the `yintercept` parameter.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param yintercept Scalar or array of y values at which to draw horizontal lines.
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
/// #let d = range(0, 10).map(i => (x: i, y: i + 2))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 2pt),
///     geom-hline(yintercept: 5, colour: rgb("#cc0000")),
///   ),
/// )
/// ```
///
/// @see @geom-vline, @geom-abline
#let geom-hline(
  yintercept: none,
  colour: rgb("#888888"),
  stroke: 0.6pt,
  alpha: 1,
  inherit-aes: false,
) = (
  kind: "layer",
  geom: "hline",
  mapping: none,
  data: none,
  params: (
    yintercept: yintercept,
    colour: colour,
    stroke: stroke,
    alpha: alpha,
  ),
  stat: "identity",
  position: "identity",
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let y-trained = ctx.trained.at("y", default: none)
  if y-trained == none or y-trained.type != "continuous" { return }
  let ys = layer.params.yintercept
  if ys == none { return }
  if type(ys) != array { ys = (ys,) }
  let (px-lo, px-hi) = ctx.px-range
  let colour = layer.params.colour
  let fill = if layer.params.alpha < 1 {
    colour.transparentize((1 - layer.params.alpha) * 100%)
  } else { colour }
  let stroke-spec = (paint: fill, thickness: layer.params.stroke)
  for y in ys {
    let cy = map-continuous(float(y), y-trained.domain, ctx.py-range)
    cetz.draw.line((px-lo, cy), (px-hi, cy), stroke: stroke-spec)
  }
}
