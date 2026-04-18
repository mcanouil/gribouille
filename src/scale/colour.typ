///! Colour and fill scales.
///!
///! `palette` accepts a Typst gradient, an array of colours, or `auto` for
///! the library default. Manual and viridis helpers are colocated in this
///! file for easy discovery.

#import "../utils/viridis.typ" as viridis-mod

/// Continuous colour scale mapping a numeric column to stroke colours.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param palette Colour source: a gradient, an array of colours, or `auto`.
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
/// #let d = range(0, 12).map(i => (x: i, y: i, z: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "z"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-colour-continuous(),),
/// )
/// ```
///
/// @see @scale-colour-viridis-c, @scale-colour-discrete, @scale-fill-continuous
#let scale-colour-continuous(name: none, palette: auto, limits: none, breaks: auto, labels: auto) = (
  kind: "scale",
  aesthetic: "colour",
  type: "continuous",
  name: name,
  palette: palette,
  limits: limits,
  breaks: breaks,
  labels: labels,
)

/// Discrete colour scale mapping categorical levels to stroke colours.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param palette Colour source: an array of colours, or `auto`.
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
///   mapping: aes(x: "x", y: "y", colour: "sp"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-colour-discrete(),),
/// )
/// ```
///
/// @see @scale-colour-manual, @scale-colour-viridis-d, @scale-fill-discrete
#let scale-colour-discrete(name: none, palette: auto, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "colour",
  type: "discrete",
  name: name,
  palette: palette,
  limits: limits,
  labels: labels,
)

/// Continuous fill scale mapping a numeric column to fill colours.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param palette Colour source: a gradient, an array of colours, or `auto`.
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
/// #let d = (
///   (grp: "a", y: 1),
///   (grp: "b", y: 2),
///   (grp: "c", y: 3),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "y"),
///   layers: (geom-col(),),
///   scales: (scale-fill-continuous(),),
/// )
/// ```
///
/// @see @scale-fill-viridis-c, @scale-fill-discrete, @scale-colour-continuous
#let scale-fill-continuous(name: none, palette: auto, limits: none, breaks: auto, labels: auto) = (
  kind: "scale",
  aesthetic: "fill",
  type: "continuous",
  name: name,
  palette: palette,
  limits: limits,
  breaks: breaks,
  labels: labels,
)

/// Discrete fill scale mapping categorical levels to fill colours.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param palette Colour source: an array of colours, or `auto`.
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
///   (grp: "a", y: 1),
///   (grp: "b", y: 2),
///   (grp: "c", y: 3),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "grp"),
///   layers: (geom-col(),),
///   scales: (scale-fill-discrete(),),
/// )
/// ```
///
/// @see @scale-fill-manual, @scale-fill-viridis-d, @scale-colour-discrete
#let scale-fill-discrete(name: none, palette: auto, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "fill",
  type: "discrete",
  name: name,
  palette: palette,
  limits: limits,
  labels: labels,
)

/// Manual discrete colour scale: supply the colour array directly.
///
/// Colours cycle through `values` in the order levels appear, unless
/// `limits` fixes the level order.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param values Array of colours, one per level.
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
///   mapping: aes(x: "x", y: "y", colour: "sp"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-colour-manual(values: (
///     rgb("#1b9e77"), rgb("#d95f02"), rgb("#7570b3"),
///   )),),
/// )
/// ```
///
/// @see @scale-colour-discrete, @scale-fill-manual
#let scale-colour-manual(values: (), name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "colour",
  type: "discrete",
  name: name,
  palette: values,
  limits: limits,
  labels: labels,
)

/// Manual discrete fill scale: supply the colour array directly.
///
/// Colours cycle through `values` in the order levels appear, unless
/// `limits` fixes the level order.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param values Array of colours, one per level.
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
///   (grp: "a", y: 1),
///   (grp: "b", y: 2),
///   (grp: "c", y: 3),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "grp"),
///   layers: (geom-col(),),
///   scales: (scale-fill-manual(values: (
///     rgb("#66c2a5"), rgb("#fc8d62"), rgb("#8da0cb"),
///   )),),
/// )
/// ```
///
/// @see @scale-fill-discrete, @scale-colour-manual
#let scale-fill-manual(values: (), name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "fill",
  type: "discrete",
  name: name,
  palette: values,
  limits: limits,
  labels: labels,
)

/// Discrete viridis colour scale.
///
/// `option` selects between `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`,
/// and `"cividis"`.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param option Palette name: `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`.
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
///   (x: 4, y: 5, sp: "d"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "sp"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-colour-viridis-d(option: "plasma"),),
/// )
/// ```
///
/// @see @scale-colour-viridis-c, @scale-colour-viridis-b, @scale-fill-viridis-d
#let scale-colour-viridis-d(option: "viridis", name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "colour",
  type: "discrete",
  name: name,
  palette: viridis-mod.palette(option),
  limits: limits,
  labels: labels,
)

/// Continuous viridis colour scale.
///
/// `option` selects between `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`,
/// and `"cividis"`.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param option Palette name: `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`.
/// @param name Legend title. Overrides any name set via @labs when both are present.
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
/// #let d = range(0, 12).map(i => (x: i, y: i, z: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "z"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-colour-viridis-c(option: "magma"),),
/// )
/// ```
///
/// @see @scale-colour-viridis-d, @scale-colour-viridis-b, @scale-fill-viridis-c
#let scale-colour-viridis-c(option: "viridis", name: none, limits: none, breaks: auto, labels: auto) = (
  kind: "scale",
  aesthetic: "colour",
  type: "continuous",
  name: name,
  palette: viridis-mod.palette(option),
  limits: limits,
  breaks: breaks,
  labels: labels,
)

/// Binned viridis colour scale.
///
/// Partitions the continuous domain into `n-breaks` equal segments, each
/// coloured from the chosen viridis palette.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param option Palette name: `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`.
/// @param n-breaks Number of bins to partition the domain into.
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param limits Pair `(lo, hi)` clipping the trained domain, or `none`.
/// @param labels Array of legend labels aligned with the bins, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 12).map(i => (x: i, y: i, z: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "z"),
///   layers: (geom-point(size: 3pt),),
///   scales: (scale-colour-viridis-b(n-breaks: 4),),
/// )
/// ```
///
/// @see @scale-colour-viridis-c, @scale-colour-viridis-d, @scale-fill-viridis-b
#let scale-colour-viridis-b(option: "viridis", n-breaks: 5, name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "colour",
  type: "continuous",
  name: name,
  palette: viridis-mod.palette(option),
  limits: limits,
  labels: labels,
  binned: true,
  n-breaks: n-breaks,
)

/// Discrete viridis fill scale.
///
/// `option` selects between `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`,
/// and `"cividis"`.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param option Palette name: `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`.
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
///   (grp: "a", y: 1),
///   (grp: "b", y: 2),
///   (grp: "c", y: 3),
///   (grp: "d", y: 4),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "grp"),
///   layers: (geom-col(),),
///   scales: (scale-fill-viridis-d(option: "cividis"),),
/// )
/// ```
///
/// @see @scale-fill-viridis-c, @scale-fill-viridis-b, @scale-colour-viridis-d
#let scale-fill-viridis-d(option: "viridis", name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "fill",
  type: "discrete",
  name: name,
  palette: viridis-mod.palette(option),
  limits: limits,
  labels: labels,
)

/// Continuous viridis fill scale.
///
/// `option` selects between `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`,
/// and `"cividis"`.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param option Palette name: `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`.
/// @param name Legend title. Overrides any name set via @labs when both are present.
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
/// #let d = range(0, 12).map(i => (grp: str(i), y: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "y"),
///   layers: (geom-col(),),
///   scales: (scale-fill-viridis-c(option: "viridis"),),
/// )
/// ```
///
/// @see @scale-fill-viridis-d, @scale-fill-viridis-b, @scale-colour-viridis-c
#let scale-fill-viridis-c(option: "viridis", name: none, limits: none, breaks: auto, labels: auto) = (
  kind: "scale",
  aesthetic: "fill",
  type: "continuous",
  name: name,
  palette: viridis-mod.palette(option),
  limits: limits,
  breaks: breaks,
  labels: labels,
)

/// Binned viridis fill scale.
///
/// Partitions the continuous domain into `n-breaks` equal segments, each
/// coloured from the chosen viridis palette.
///
/// @category Scales
/// @stability stable
/// @since 0.1.0
///
/// @param option Palette name: `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or `"cividis"`.
/// @param n-breaks Number of bins to partition the domain into.
/// @param name Legend title. Overrides any name set via @labs when both are present.
/// @param limits Pair `(lo, hi)` clipping the trained domain, or `none`.
/// @param labels Array of legend labels aligned with the bins, or `auto`.
///
/// @returns Scale object consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 12).map(i => (grp: str(i), y: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y", fill: "y"),
///   layers: (geom-col(),),
///   scales: (scale-fill-viridis-b(n-breaks: 4),),
/// )
/// ```
///
/// @see @scale-fill-viridis-c, @scale-fill-viridis-d, @scale-colour-viridis-b
#let scale-fill-viridis-b(option: "viridis", n-breaks: 5, name: none, limits: none, labels: auto) = (
  kind: "scale",
  aesthetic: "fill",
  type: "continuous",
  name: name,
  palette: viridis-mod.palette(option),
  limits: limits,
  labels: labels,
  binned: true,
  n-breaks: n-breaks,
)
