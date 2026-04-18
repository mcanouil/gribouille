///! Classic theme preset.
///!
///! White panel background with visible axis borders and no gridlines.
///! Close to the ggplot2 `theme_classic()` look.

/// Classic theme: white panel, axis borders, no gridlines.
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
///   theme: theme-classic(),
/// )
/// ```
///
/// @see @theme-grey, @theme-minimal, @theme-void, @theme
#let theme-classic() = (
  kind: "theme",
  name: "classic",
  panel-fill: white,
  grid-colour: none,
  grid-thickness: 0pt,
  axis-colour: black,
  axis-thickness: 0.6pt,
)
