/// Bind column names to visual channels to form an aesthetic mapping.
///
/// Aesthetic mappings tell @plot how to turn data columns into visual
/// properties: which column drives the x axis, which becomes a colour, etc.
/// Pass the result as the `mapping` argument of @plot or any geom layer.
///
/// @category Core
/// @stability stable
/// @since 0.1.0
///
/// @param x Column name for the x position.
/// @param y Column name for the y position.
/// @param colour Column name driving the stroke colour.
/// @param fill Column name driving the fill colour.
/// @param size Column name driving marker or line size.
/// @param alpha Column name driving opacity.
/// @param group Column name used to partition layers that connect observations.
/// @param shape Column name driving marker shape.
/// @param linetype Column name driving line dash pattern.
/// @param label Column name used by @geom-text and @geom-label.
/// @param xmin Column name for the lower x bound (ribbons, error bars).
/// @param xmax Column name for the upper x bound.
/// @param ymin Column name for the lower y bound.
/// @param ymax Column name for the upper y bound.
/// @param xend Column name for the x end point of a segment.
/// @param yend Column name for the y end point of a segment.
/// @param xintercept Column name or scalar for vertical reference lines.
/// @param yintercept Column name or scalar for horizontal reference lines.
/// @param slope Slope for oblique reference lines (@geom-abline).
/// @param intercept Intercept for oblique reference lines.
/// @param weight Column name carrying per-row statistical weights.
///
/// @returns Dictionary tagged `kind: "aes"`, consumed by @plot and geom layers.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let iris = (
///   (x: 5.1, y: 3.5, sp: "setosa"),
///   (x: 7.0, y: 3.2, sp: "versicolor"),
///   (x: 6.3, y: 3.3, sp: "virginica"),
/// )
/// #plot(
///   data: iris,
///   mapping: aes(x: "x", y: "y", colour: "sp"),
///   layers: (geom-point(size: 3pt),),
/// )
/// ```
///
/// @see @plot, @geom-point, @as-factor
#let aes(
  x: none,
  y: none,
  colour: none,
  fill: none,
  size: none,
  alpha: none,
  group: none,
  shape: none,
  linetype: none,
  label: none,
  xmin: none,
  xmax: none,
  ymin: none,
  ymax: none,
  xend: none,
  yend: none,
  xintercept: none,
  yintercept: none,
  slope: none,
  intercept: none,
  weight: none,
) = (
  kind: "aes",
  x: x,
  y: y,
  colour: colour,
  fill: fill,
  size: size,
  alpha: alpha,
  group: group,
  shape: shape,
  linetype: linetype,
  label: label,
  xmin: xmin,
  xmax: xmax,
  ymin: ymin,
  ymax: ymax,
  xend: xend,
  yend: yend,
  xintercept: xintercept,
  yintercept: yintercept,
  slope: slope,
  intercept: intercept,
  weight: weight,
)
