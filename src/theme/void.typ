///! Void theme preset.
///!
///! No axes, grid, or panel background. Useful when the plot stands on its
///! own without an axis frame (e.g. maps, annotated figures).

/// Void theme: no axes, no grid, no panel background.
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
///   theme: theme-void(),
/// )
/// ```
///
/// @see @theme-grey, @theme-minimal, @theme-classic, @theme
#let theme-void() = (
  kind: "theme",
  name: "void",
  panel-fill: none,
  grid-colour: none,
  grid-thickness: 0pt,
  axis-colour: none,
  axis-thickness: 0pt,
  tick-length: 0,
  tick-labels: false,
  axis-title-size: 0pt,
)
