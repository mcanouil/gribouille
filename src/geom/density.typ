#import "../layer.typ": make-layer, split-aes-params
#import "../stat/density.typ": stat-density

///! Smoothed density curve of the x sample.
///!
///! Continuous counterpart of \@geom-histogram: runs \@stat-density (a
///! Gaussian kernel density estimate) and draws the curve as an area
///! outline closed along the baseline. Unfilled by default; set `fill`
///! or map the fill aesthetic to shade under the curve.

/// Density layer: Gaussian kernel density estimate of the x aesthetic.
///
/// Mapping must provide `x`. Discrete colour, fill, or `group` mappings
/// split rows into one density curve per group.
///
/// \@category Geoms
/// \@subcategory Distributions
/// \@stability stable
/// \@since 0.5.0
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Must map `x`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param bw Kernel bandwidth. `auto` applies Silverman's rule of thumb; pass a positive number to fix it.
///
/// \@param adjust Bandwidth multiplier: `adjust: 0.5` halves the smoothing, `adjust: 2` doubles it.
///
/// \@param n Number of evenly spaced grid points the density is evaluated at.
///
/// \@param trim Whether to restrict the curve to the data range instead of letting it decay to the baseline.
///
/// \@param colour Fixed outline colour. `auto` resolves via the colour scale, falling back to the theme `ink`.
///
/// \@param fill Fixed fill colour under the curve. `auto` (default) leaves the curve unfilled until the fill aesthetic is mapped, then shades under it via the fill scale; a fixed colour fills unconditionally and `none` disables the fill.
///
/// \@param stroke Outline thickness (a Typst length) or stroke dictionary; `none` disables the outline.
///
/// \@param alpha Fill opacity in `[0, 1]`.
///
/// \@param stat Statistical transform. `auto` builds \@stat-density from the parameters above; pass a stat name or stat object to override.
///
/// \@param position Position adjustment name. Usually `"identity"`.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Density curve of a bimodal sample.
/// ```
/// //| alt: "Density chart with x on the horizontal axis and estimated density on the vertical axis, a smooth bimodal curve with peaks near x = 2 and x = 7."
/// #let d = range(0, 60).map(i => (
///   x: if calc.rem(i, 2) == 0 { 2 + calc.sin(i * 1.3) * 1.2 } else {
///     7 + calc.cos(i * 0.9) * 1.4
///   },
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x"),
///   layers: (geom-density(),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Map `fill` to a discrete column to overlay one shaded density
/// per group.
/// ```
/// //| alt: "Two overlaid semi-transparent density curves of x coloured by group (a, b) via the fill aesthetic, group b shifted right of group a."
/// #let d = ()
/// #for grp in ("a", "b") {
///   for i in range(0, 40) {
///     d.push((x: calc.sin(i * 0.7) * 2 + (if grp == "b" { 4 } else { 0 }), grp: grp))
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: "x", fill: "grp"),
///   layers: (geom-density(alpha: 0.4),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@stat-density, \@geom-histogram, \@geom-freqpoly
#let geom-density(
  mapping: none,
  data: none,
  bw: auto,
  adjust: 1,
  n: 512,
  trim: false,
  colour: auto,
  fill: auto,
  stroke: auto,
  alpha: auto,
  stat: auto,
  position: "identity",
  key: auto,
  inherit-aes: true,
  ..args,
) = make-layer(
  "area",
  mapping: mapping,
  data: data,
  params: (
    colour: colour,
    fill: fill,
    stroke: stroke,
    alpha: alpha,
    direction: none,
    outline-role: "ink",
    fill-role: none,
  )
    + split-aes-params("geom-density", args),
  stat: if stat == auto {
    stat-density(bw: bw, adjust: adjust, n: n, trim: trim)
  } else { stat },
  position: position,
  key: key,
  inherit-aes: inherit-aes,
)
