///! Boxplots from pre-summarised quantile columns.
///!
///! v1 expects the dataset to already provide `min`, `q1`, `median`, `q3`,
///! `max` per group. Automatic quantile computation is deferred to a later
///! release behind a WASM stat plugin.

/// Boxplot layer drawn from pre-computed quantile columns.
///
/// The layer expects the dataset to carry the five-number summary per group
/// (rows keyed by the x aesthetic). It does not compute quantiles itself.
///
/// @category Geoms
/// @stability experimental
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Falls back to the plot mapping when `none`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param width Box width as a fraction of the category width (0 to 1).
/// @param fill Box fill colour. `auto` resolves via the fill scale or a neutral default.
/// @param stroke Box outline thickness.
/// @param alpha Box opacity in `[0, 1]`.
/// @param stat Statistical transform name. Usually `"identity"` for pre-summarised data.
/// @param position Position adjustment name (`"dodge"` by default for grouped boxes).
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (grp: "a", min: 1, q1: 2, median: 3, q3: 4, max: 5),
///   (grp: "b", min: 2, q1: 3, median: 4, q3: 5, max: 7),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp"),
///   layers: (geom-boxplot(),),
/// )
/// ```
///
/// @see @geom-col, @position-dodge
#let geom-boxplot(
  mapping: none,
  data: none,
  width: 0.7,
  fill: auto,
  stroke: 0.5pt,
  alpha: 1,
  stat: "identity",
  position: "dodge",
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "boxplot",
  mapping: mapping,
  data: data,
  params: (width: width, fill: fill, stroke: stroke, alpha: alpha),
  stat: stat,
  position: position,
  inherit-aes: inherit-aes,
)
