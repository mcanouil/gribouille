///! Continuous size scale.
///!
///! Maps a numeric column onto a pair of Typst lengths describing the output
///! range of marker or line sizes.

/// Continuous size scale mapping a numeric column to a size range.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param range Pair of Typst lengths `(min, max)` bounding the output size.
/// @param limits Pair `(lo, hi)` clipping the trained domain, or `none`.
/// @param breaks Array of break values for the legend, or `auto`.
/// @param labels Array of legend labels aligned with `breaks`, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i, w: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", size: "w"),
///   layers: (geom-point(),),
///   scales: (scale-size-continuous(range: (1pt, 6pt)),),
/// )
/// ```
///
/// @see @scale-shape, @scale-colour-continuous
#let scale-size-continuous(name: none, range: (1pt, 6pt), limits: none, breaks: auto, labels: auto) = (
  kind: "scale",
  aesthetic: "size",
  type: "continuous",
  name: name,
  range: range,
  limits: limits,
  breaks: breaks,
  labels: labels,
)
