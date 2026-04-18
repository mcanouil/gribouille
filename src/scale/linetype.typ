///! Linetype scale.
///!
///! Maps discrete levels onto CeTZ dash keywords consumed by @geom-line
///! (`"solid"`, `"dashed"`, `"dotted"`, `"dash-dotted"`, etc.).

#import "../utils/palette.typ": default-linetypes

/// Discrete linetype scale: maps levels to dash-pattern keywords.
///
/// Pass a custom array of keywords via `palette` to override the default
/// linetype set.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param palette Array of dash keywords, or `auto` for the library default.
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
///   (x: 1, y: 2, grp: "a"),
///   (x: 2, y: 4, grp: "a"),
///   (x: 3, y: 3, grp: "a"),
///   (x: 1, y: 1, grp: "b"),
///   (x: 2, y: 2, grp: "b"),
///   (x: 3, y: 4, grp: "b"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", linetype: "grp"),
///   layers: (geom-line(stroke: 1pt),),
///   scales: (scale-linetype(),),
/// )
/// ```
///
/// @see @scale-linetype-manual, @geom-line
#let scale-linetype(name: none, palette: auto, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "linetype",
  type: "discrete",
  name: name,
  palette: if palette == auto { default-linetypes } else { palette },
  limits: limits,
  labels: labels,
)

/// Manual discrete linetype scale: supply the dash-keyword array directly.
///
/// Keywords cycle through `values` in the order levels appear, unless
/// `limits` fixes the level order.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param values Array of dash keywords, one per level.
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
///   (x: 1, y: 2, grp: "a"),
///   (x: 2, y: 4, grp: "a"),
///   (x: 1, y: 1, grp: "b"),
///   (x: 2, y: 2, grp: "b"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", linetype: "grp"),
///   layers: (geom-line(stroke: 1pt),),
///   scales: (scale-linetype-manual(values: ("solid", "dashed")),),
/// )
/// ```
///
/// @see @scale-linetype, @geom-line
#let scale-linetype-manual(values: (), name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "linetype",
  type: "discrete",
  name: name,
  palette: values,
  limits: limits,
  labels: labels,
)
