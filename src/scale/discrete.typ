///! Discrete position scales for x and y.
///!
///! Use these when the mapped column is categorical. `limits` controls which
///! levels appear and in what order.

/// Discrete x scale: axis title, level ordering, and tick labels.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Axis title. Overrides any name set via @labs when both are present.
/// @param limits Array of level names controlling order and inclusion, or `none` for first-seen order.
/// @param labels Array of tick labels aligned with `limits`, or `auto`.
/// @param expand Expansion added to each side of the domain, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (grp: "b", y: 3),
///   (grp: "a", y: 5),
///   (grp: "c", y: 2),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y"),
///   layers: (geom-col(),),
///   scales: (scale-x-discrete(limits: ("a", "b", "c")),),
/// )
/// ```
///
/// @see @scale-y-discrete, @scale-x-continuous
#let scale-x-discrete(name: none, limits: none, labels: auto, expand: auto) = (
  kind: "scale",
  aesthetic: "x",
  type: "discrete",
  name: name,
  limits: limits,
  labels: labels,
  expand: expand,
)

/// Discrete y scale: axis title, level ordering, and tick labels.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Axis title. Overrides any name set via @labs when both are present.
/// @param limits Array of level names controlling order and inclusion, or `none` for first-seen order.
/// @param labels Array of tick labels aligned with `limits`, or `auto`.
/// @param expand Expansion added to each side of the domain, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (grp: "b", x: 3),
///   (grp: "a", x: 5),
///   (grp: "c", x: 2),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "grp"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-y-discrete(limits: ("a", "b", "c")),),
/// )
/// ```
///
/// @see @scale-x-discrete, @scale-y-continuous
#let scale-y-discrete(name: none, limits: none, labels: auto, expand: auto) = (
  kind: "scale",
  aesthetic: "y",
  type: "discrete",
  name: name,
  limits: limits,
  labels: labels,
  expand: expand,
)
