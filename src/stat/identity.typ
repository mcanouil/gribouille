///! Pass-through statistic.
///!
///! Use `stat-identity` whenever you want a layer to draw the dataset as-is,
///! without any pre-aggregation or transformation.

/// Identity statistic: returns data and mapping unchanged.
///
/// Useful as an explicit marker; most geoms default to this statistic.
///
/// @category Stats
/// @stability stable
/// @since 0.1.0
///
/// @returns Statistic object with `name: "identity"`, consumed by geom layers.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2),
///   (x: 2, y: 4),
///   (x: 3, y: 3),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt, stat: "identity"),),
/// )
/// ```
///
/// @see @stat-count, @stat-bin, @stat-smooth
#let stat-identity() = (kind: "stat", name: "identity")

#let apply(data, mapping, params: (:)) = (data: data, mapping: mapping)
