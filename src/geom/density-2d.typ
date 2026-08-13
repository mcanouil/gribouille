#import "../layer.typ": make-layer, split-aes-params
#import "../stat/density-2d.typ": stat-density-2d

///! Density contour lines of an `(x, y)` sample.
///!
///! 2D counterpart of \@geom-density: runs \@stat-density-2d (a Gaussian
///! kernel density estimate on a regular grid) and traces the surface's
///! iso-lines through the path drawing used by \@geom-contour.

/// 2D density layer: contour lines of the estimated `(x, y)` density.
///
/// Mapping must provide `x` and `y`; the layer accepts raw observations,
/// no pre-computed grid is needed. Map `colour` to `after-stat("_level")`
/// to shade the lines by density level.
///
/// \@category Geoms
/// \@subcategory Distributions
/// \@stability stable
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Must map `x` and `y`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param bw Kernel standard deviation per axis. `auto` derives it per axis from R's `bw.nrd / 4`; pass a number for both axes or an `(x, y)` tuple.
///
/// \@param adjust Bandwidth multiplier: `adjust: 0.5` halves the smoothing.
///
/// \@param n Density grid resolution per axis: a number or an `(x, y)` tuple.
///
/// \@param bins Target contour-level count when `breaks` and `binwidth` are unset.
///
/// \@param binwidth Fixed step between levels. Overrides `bins`.
///
/// \@param breaks Explicit array of contour levels. Overrides `bins` and `binwidth`.
///
/// \@param stroke Line thickness (a Typst length).
///
/// \@param colour Fixed line colour. `auto` resolves via the colour scale.
///
/// \@param alpha Line opacity in `[0, 1]`.
///
/// \@param linetype Dash keyword. `auto` honours the linetype scale.
///
/// \@param stat Statistical transform. `auto` builds \@stat-density-2d from the parameters above; pass a stat name or stat object to override.
///
/// \@param position Position adjustment name. Usually `"identity"`.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Density contours around two point clouds.
/// ```
/// //| alt: "Scatter of two point clouds centred near (2, 2) and (6, 5) overlaid with concentric density contour lines around each cloud."
/// #let d = range(0, 60).map(i => {
///   let lobe = calc.rem(i, 2)
///   (
///     x: 2 + lobe * 4 + calc.sin(i * 1.7) * 0.8,
///     y: 2 + lobe * 3 + calc.cos(i * 2.3) * 0.8,
///   )
/// })
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 1.5pt, alpha: 0.5),
///     geom-density-2d(),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@stat-density-2d, \@geom-density-2d-filled, \@geom-contour
#let geom-density-2d(
  mapping: none,
  data: none,
  bw: auto,
  adjust: 1,
  n: 25,
  bins: 10,
  binwidth: none,
  breaks: auto,
  stroke: auto,
  colour: auto,
  alpha: auto,
  linetype: auto,
  stat: auto,
  position: "identity",
  key: auto,
  inherit-aes: true,
  ..args,
) = make-layer(
  "path",
  mapping: mapping,
  data: data,
  params: (
    stroke: stroke,
    stroke-fallback: 0.6pt,
    colour: colour,
    alpha: alpha,
    linetype: linetype,
  )
    + split-aes-params("geom-density-2d", args),
  stat: if stat == auto {
    stat-density-2d(
      bw: bw,
      adjust: adjust,
      n: n,
      bins: bins,
      binwidth: binwidth,
      breaks: breaks,
    )
  } else { stat },
  position: position,
  key: key,
  inherit-aes: inherit-aes,
)
