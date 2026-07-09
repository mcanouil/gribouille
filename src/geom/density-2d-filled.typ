#import "../layer.typ": make-layer, split-aes-params
#import "../stat/density-2d-filled.typ": stat-density-2d-filled

///! Filled density bands of an `(x, y)` sample.
///!
///! Filled counterpart of \@geom-density-2d: runs \@stat-density-2d-filled
///! and shades the estimated density surface as per-cell iso-band polygons
///! through the polygon drawing used by \@geom-contour-filled. The bands
///! tile per grid cell, so the default `stroke: none` keeps the shading
///! seamless.

/// Filled 2D density layer: shaded bands of the estimated `(x, y)` density.
///
/// Mapping must provide `x` and `y`; the layer accepts raw observations,
/// no pre-computed grid is needed. The stat binds `fill` to the band's
/// density level, so a continuous fill scale shades by height.
///
/// \@category Geoms
/// \@subcategory Distributions
/// \@stability stable
/// \@since 0.5.0
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
/// \@param bins Target band count when `breaks` and `binwidth` are unset.
///
/// \@param binwidth Fixed step between band edges. Overrides `bins`.
///
/// \@param breaks Explicit array of band edges. Overrides `bins` and `binwidth`.
///
/// \@param colour Fixed polygon outline colour. `auto` resolves via the colour scale.
///
/// \@param fill Fixed band fill. `auto` shades by density level through the fill scale.
///
/// \@param stroke Outline thickness (a Typst length); `none` (default) keeps the per-cell tiling seamless.
///
/// \@param alpha Fill opacity in `[0, 1]`.
///
/// \@param stat Statistical transform. `auto` builds \@stat-density-2d-filled from the parameters above; pass a stat name or stat object to override.
///
/// \@param position Position adjustment name. Usually `"identity"`.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Shaded density bands of two point clouds.
/// ```
/// //| alt: "Filled density bands shading two point clouds centred near (2, 2) and (6, 5), darker where the estimated density is higher."
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
///   layers: (geom-density-2d-filled(),),
///   scales: scales(
///     x: scale-continuous(expand: (0,0)),
///     y: scale-continuous(expand: (0,0)),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@stat-density-2d-filled, \@geom-density-2d, \@geom-contour-filled
#let geom-density-2d-filled(
  mapping: none,
  data: none,
  bw: auto,
  adjust: 1,
  n: 25,
  bins: 10,
  binwidth: none,
  breaks: auto,
  colour: auto,
  fill: auto,
  stroke: none,
  alpha: auto,
  stat: auto,
  position: "identity",
  key: auto,
  inherit-aes: true,
  ..args,
) = make-layer(
  "polygon",
  mapping: mapping,
  data: data,
  params: (
    colour: colour,
    fill: fill,
    stroke: stroke,
    alpha: alpha,
    tile-seam: true,
  )
    + split-aes-params("geom-density-2d-filled", args),
  stat: if stat == auto {
    stat-density-2d-filled(
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
