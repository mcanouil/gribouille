#import "render.typ": render-plot

/// Compose a layered plot from data, aesthetics, and geom layers.
///
/// `plot` is the entry point of the grammar: it resolves the dataset, wires up
/// the aesthetic mapping, trains scales against the data, applies coordinate,
/// facet, theme, and label choices, and dispatches to the internal renderer.
/// Call it once per figure, passing the layers you want to stack.
///
/// @category Core
/// @stability stable
/// @since 0.1.0
///
/// @param data Array of row dictionaries. Each row is a `(column: value, ...)` dict.
/// @param mapping Aesthetic mapping built with @aes. Maps column names to visual channels.
/// @param layers Array of geom layers (e.g. @geom-point, @geom-line). Drawn in order.
/// @param scales Array of scale objects overriding defaults (@scale-x-continuous, @scale-colour-viridis-d, etc.).
/// @param coord Coordinate system. Defaults to @coord-cartesian when `none`.
/// @param facet Faceting specification built with @facet-wrap or @facet-grid.
/// @param theme Theme object (e.g. @theme-grey, @theme-minimal, @theme-classic). Controls non-data ink.
/// @param labs Labels dictionary built with @labs (title, subtitle, caption, axis titles).
/// @param width Total plot width, including axes and legends.
/// @param height Total plot height, including axes and legends.
///
/// @returns Typst content block containing the rendered figure.
///
/// @example
/// ```
/// //| width: 12cm
/// //| height: 7cm
/// #let mtcars = (
///   (mpg: 21.0, wt: 2.620, cyl: "6"),
///   (mpg: 22.8, wt: 2.320, cyl: "4"),
///   (mpg: 18.7, wt: 3.440, cyl: "8"),
///   (mpg: 16.4, wt: 4.070, cyl: "8"),
///   (mpg: 33.9, wt: 1.835, cyl: "4"),
/// )
/// #plot(
///   data: mtcars,
///   mapping: aes(x: "wt", y: "mpg", colour: "cyl"),
///   layers: (geom-point(size: 3pt),),
///   labs: labs(title: "Fuel economy vs. weight"),
/// )
/// ```
///
/// @see @aes, @geom-point, @coord-cartesian, @facet-wrap, @theme-grey, @labs
#let plot(
  data: none,
  mapping: none,
  layers: (),
  scales: (),
  coord: none,
  facet: none,
  theme: none,
  labs: none,
  width: 10cm,
  height: 7cm,
) = {
  let spec = (
    data: data,
    mapping: mapping,
    layers: layers,
    scales: scales,
    coord: coord,
    facet: facet,
    theme: theme,
    labs: labs,
    width: width,
    height: height,
  )
  render-plot(spec)
}
