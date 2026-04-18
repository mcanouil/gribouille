///! Cartesian coordinate system.
///!
///! The default coordinate system used when no `coord` is passed to @plot.
///! `xlim` and `ylim` clip the rendered panel without dropping rows, unlike
///! scale limits which remove rows outside the domain.

/// Cartesian coordinate system with optional panel clipping.
///
/// Clipping via `xlim`/`ylim` preserves the trained scales; rows outside
/// are still used for training but drawn off-panel.
///
/// @category Coord
/// @stability stable
/// @since 0.1.0
///
/// @param xlim Pair `(lo, hi)` clipping the drawn x range, or `none`.
/// @param ylim Pair `(lo, hi)` clipping the drawn y range, or `none`.
/// @param expand Whether to add a small margin around the data range.
///
/// @returns Coordinate dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 20).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   coord: coord-cartesian(xlim: (2, 15), ylim: (0, 8)),
/// )
/// ```
///
/// @see @plot, @scale-x-continuous
#let coord-cartesian(xlim: none, ylim: none, expand: true) = (
  kind: "coord",
  coord: "cartesian",
  xlim: xlim,
  ylim: ylim,
  expand: expand,
)
