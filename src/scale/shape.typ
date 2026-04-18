///! Shape scale.
///!
///! Maps discrete levels onto marker-shape keywords consumed by @geom-point
///! (`"circle"`, `"square"`, `"triangle"`, `"diamond"`, `"cross"`, `"x"`,
///! `"star"`, `"triangle-down"`).

#import "../utils/palette.typ": default-shapes

/// Discrete shape scale: maps levels to marker-shape keywords.
///
/// Pass a custom array of keywords via `palette` to override the default
/// shape set.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param palette Array of shape keywords, or `auto` for the library default.
/// @param limits Array of level names controlling order and inclusion, or `none`.
/// @param labels Array of legend labels aligned with `limits`, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2, sp: "a"),
///   (x: 2, y: 4, sp: "b"),
///   (x: 3, y: 3, sp: "c"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", shape: "sp"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-shape(),),
/// )
/// ```
///
/// @see @scale-shape-manual, @geom-point
#let scale-shape(name: none, palette: auto, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "shape",
  type: "discrete",
  name: name,
  palette: if palette == auto { default-shapes } else { palette },
  limits: limits,
  labels: labels,
)

/// Manual discrete shape scale: supply the shape-keyword array directly.
///
/// Keywords cycle through `values` in the order levels appear, unless
/// `limits` fixes the level order.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param values Array of shape keywords, one per level.
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param limits Array of level names controlling order and inclusion, or `none`.
/// @param labels Array of legend labels aligned with `limits`, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2, sp: "a"),
///   (x: 2, y: 4, sp: "b"),
///   (x: 3, y: 3, sp: "c"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", shape: "sp"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-shape-manual(
///     values: ("circle", "triangle", "diamond"),
///   ),),
/// )
/// ```
///
/// @see @scale-shape, @geom-point
#let scale-shape-manual(values: (), name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "shape",
  type: "discrete",
  name: name,
  palette: values,
  limits: limits,
  labels: labels,
)
