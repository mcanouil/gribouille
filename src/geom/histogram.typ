///! Histogram of a continuous variable.
///!
///! Uses @stat-bin to partition x into uniform-width bins and draws bars of
///! the per-bin counts. Choose either `bins` (count) or `binwidth` (width).

/// Histogram layer: bars of binned counts along the x aesthetic.
///
/// The layer runs @stat-bin over the x column, then draws one bar per bin.
/// Supply `bins` for a target bin count or `binwidth` to fix the width.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Must map `x`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param bins Target number of bins when `binwidth` is `none`.
/// @param binwidth Fixed bin width. Overrides `bins` when set.
/// @param width Bar width as a fraction of the bin width (0 to 1).
/// @param fill Bar fill colour. `auto` resolves via the fill scale or a neutral default.
/// @param stroke Bar outline; `none` means no border.
/// @param alpha Bar opacity in `[0, 1]`.
/// @param position Position adjustment name. Usually `"identity"`.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 40).map(i => (
///   x: calc.sin(i * 0.3) * 5 + i * 0.2,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x"),
///   layers: (geom-histogram(bins: 12),),
/// )
/// ```
///
/// @see @stat-bin, @geom-bar, @geom-col
#let geom-histogram(
  mapping: none,
  data: none,
  bins: 30,
  binwidth: none,
  width: 1.0,
  fill: auto,
  stroke: none,
  alpha: 1,
  position: "identity",
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "col",
  mapping: mapping,
  data: data,
  params: (
    fill: fill,
    stroke: stroke,
    alpha: alpha,
    width: width,
    bins: bins,
    binwidth: binwidth,
  ),
  stat: "bin",
  position: position,
  inherit-aes: inherit-aes,
)
