///! Vertical reference line(s) at given x intercepts.
///!
///! Works only with a continuous x scale. `xintercept` accepts a single value
///! or an array for drawing multiple reference lines at once.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-continuous

/// Vertical reference line at one or more x intercepts.
///
/// `xintercept` can be a scalar or an array. The layer does not inherit the
/// plot mapping by default; it draws purely from the `xintercept` parameter.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param xintercept Scalar or array of x values at which to draw vertical lines.
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
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 2pt),
///     geom-vline(xintercept: (3, 6), colour: rgb("#4c78a8")),
///   ),
/// )
/// ```
///
/// @see @geom-hline, @geom-abline
#let geom-vline(
  xintercept: none,
  colour: rgb("#888888"),
  stroke: 0.6pt,
  alpha: 1,
  inherit-aes: false,
) = (
  kind: "layer",
  geom: "vline",
  mapping: none,
  data: none,
  params: (
    xintercept: xintercept,
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
  if x-trained == none or x-trained.type != "continuous" { return }
  let xs = layer.params.xintercept
  if xs == none { return }
  if type(xs) != array { xs = (xs,) }
  let (py-lo, py-hi) = ctx.py-range
  let colour = layer.params.colour
  let fill = if layer.params.alpha < 1 {
    colour.transparentize((1 - layer.params.alpha) * 100%)
  } else { colour }
  let stroke-spec = (paint: fill, thickness: layer.params.stroke)
  for x in xs {
    let cx = map-continuous(float(x), x-trained.domain, ctx.px-range)
    cetz.draw.line((cx, py-lo), (cx, py-hi), stroke: stroke-spec)
  }
}
