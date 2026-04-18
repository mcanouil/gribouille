///! Minimal theme preset.
///!
///! White panel with thin light grey gridlines, no axis lines, no tick marks.
///! Matches ggplot2's `theme_minimal()`.

/// Minimal theme: white panel, light grey gridlines, no axis lines.
///
/// Equivalent to ggplot2's `theme_minimal()`. For the gribouille default
/// (grey panel with white gridlines) use @theme-grey.
///
/// @category Themes
/// @stability stable
/// @since 0.1.0
///
/// @returns Theme dictionary consumed by @plot.
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
///   theme: theme-minimal(),
/// )
/// ```
///
/// @see @theme-grey, @theme-classic, @theme-void, @theme
#let theme-minimal() = (
  kind: "theme",
  name: "minimal",
  panel-fill: none,
  grid-colour: rgb("#ebebeb"),
  grid-thickness: 0.4pt,
  axis-colour: none,
  axis-thickness: 0pt,
  tick-length: 0,
)
