///! Grey theme preset.
///!
///! Light grey panel background with white gridlines and thin black axes.
///! Matches ggplot2's `theme_gray()` and is the library default.

/// Grey theme: light grey panel with white gridlines.
///
/// This is the gribouille default, equivalent to ggplot2's `theme_gray()`.
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
///   theme: theme-grey(),
/// )
/// ```
///
/// @see @theme-minimal, @theme-classic, @theme-void, @theme
#let theme-grey() = (
  kind: "theme",
  name: "grey",
  panel-fill: rgb("#f2f2f2"),
  grid-colour: white,
  grid-thickness: 0.5pt,
  axis-colour: black,
  axis-thickness: 0.5pt,
)
