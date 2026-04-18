///! Structured theme elements.
///!
///! Mirrors ggplot2's `element_*` constructors. @theme translates these
///! into the flat theme fields consumed internally by `merge-theme`.

/// Text element: font size, weight, colour, and angle.
///
/// Pass the result to @theme under keys like `axis-text`, `axis-title`,
/// `legend-text`, or `legend-title`.
///
/// @category Themes
/// @stability stable
/// @since 0.1.0
///
/// @param size Text size (a Typst length), or `none` to inherit.
/// @param weight Font weight (e.g. `"regular"`, `"bold"`), or `none`.
/// @param colour Text colour, or `none` to inherit.
/// @param angle Rotation angle (a Typst angle), or `none`.
///
/// @returns Element dictionary consumed by @theme.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(axis-title: element-text(size: 14pt)),
/// )
/// ```
///
/// @see @theme, @element-line, @element-rect, @element-blank
#let element-text(size: none, weight: none, colour: none, angle: none) = (
  kind: "element-text",
  size: size,
  weight: weight,
  colour: colour,
  angle: angle,
)

/// Line element: colour and thickness.
///
/// Pass the result to @theme under keys like `panel-grid` or `axis-line`.
///
/// @category Themes
/// @stability stable
/// @since 0.1.0
///
/// @param colour Line colour, or `none` to inherit.
/// @param thickness Line thickness (a Typst length), or `none`.
///
/// @returns Element dictionary consumed by @theme.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-grid: element-line(colour: rgb("#d9cfbf"))),
/// )
/// ```
///
/// @see @theme, @element-text, @element-rect, @element-blank
#let element-line(colour: none, thickness: none) = (
  kind: "element-line",
  colour: colour,
  thickness: thickness,
)

/// Rectangle element: fill and stroke.
///
/// Pass the result to @theme under keys like `panel-background`.
///
/// @category Themes
/// @stability stable
/// @since 0.1.0
///
/// @param fill Rectangle fill colour, or `none` to inherit.
/// @param stroke Rectangle stroke, or `none` to inherit.
///
/// @returns Element dictionary consumed by @theme.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-background: element-rect(fill: rgb("#f7f0e7"))),
/// )
/// ```
///
/// @see @theme, @element-text, @element-line, @element-blank
#let element-rect(fill: none, stroke: none) = (
  kind: "element-rect",
  fill: fill,
  stroke: stroke,
)

/// Blank element: hides the corresponding theme element.
///
/// Pass the result to @theme under keys like `panel-grid` or `axis-line`
/// to turn them off entirely.
///
/// @category Themes
/// @stability stable
/// @since 0.1.0
///
/// @returns Element dictionary consumed by @theme.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-grid: element-blank()),
/// )
/// ```
///
/// @see @theme, @element-text, @element-line, @element-rect
#let element-blank() = (kind: "element-blank")
