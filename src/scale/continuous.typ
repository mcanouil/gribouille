///! Continuous position scales for x and y.
///!
///! Use these to override the default continuous axis: set `limits` to clip,
///! `breaks` and `labels` to control tick marks, or `trans` to apply `"log10"`
///! or `"sqrt"` transformations.

/// Continuous x scale: axis title, limits, breaks, labels, and transformation.
///
/// `trans` accepts `"identity"`, `"log10"`, and `"sqrt"`.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Axis title. Overrides any name set via @labs when both are present.
/// @param limits Pair `(lo, hi)` clipping the trained domain, or `none` for automatic limits.
/// @param breaks Array of break values, or `auto` for automatic tick selection.
/// @param labels Array of tick labels aligned with `breaks`, or `auto`.
/// @param trans Transformation keyword: `"identity"`, `"log10"`, or `"sqrt"`.
/// @param expand Expansion added to each side of the domain, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(1, 11).map(i => (x: i, y: i * i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: (scale-x-continuous(name: "Index", limits: (0, 12)),),
/// )
/// ```
///
/// @see @scale-y-continuous, @scale-x-discrete, @coord-cartesian
#let scale-x-continuous(
  name: none,
  limits: none,
  breaks: auto,
  labels: auto,
  trans: "identity",
  expand: auto,
) = (
  kind: "scale",
  aesthetic: "x",
  type: "continuous",
  name: name,
  limits: limits,
  breaks: breaks,
  labels: labels,
  trans: trans,
  expand: expand,
)

/// Continuous y scale: axis title, limits, breaks, labels, and transformation.
///
/// `trans` accepts `"identity"`, `"log10"`, and `"sqrt"`.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Axis title. Overrides any name set via @labs when both are present.
/// @param limits Pair `(lo, hi)` clipping the trained domain, or `none` for automatic limits.
/// @param breaks Array of break values, or `auto` for automatic tick selection.
/// @param labels Array of tick labels aligned with `breaks`, or `auto`.
/// @param trans Transformation keyword: `"identity"`, `"log10"`, or `"sqrt"`.
/// @param expand Expansion added to each side of the domain, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(1, 11).map(i => (x: i, y: calc.pow(2, i)))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: (scale-y-continuous(name: "Value", trans: "log10"),),
/// )
/// ```
///
/// @see @scale-x-continuous, @scale-y-discrete
#let scale-y-continuous(
  name: none,
  limits: none,
  breaks: auto,
  labels: auto,
  trans: "identity",
  expand: auto,
) = (
  kind: "scale",
  aesthetic: "y",
  type: "continuous",
  name: name,
  limits: limits,
  breaks: breaks,
  labels: labels,
  trans: trans,
  expand: expand,
)
