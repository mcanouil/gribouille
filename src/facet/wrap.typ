///! Wrap faceting.
///!
///! One panel per level of a discrete variable, wrapped into a grid of
///! `ncol` columns (or `nrow` rows). v1 supports shared scales only.

#import "shared.typ"

/// Wrap facets: one panel per level of a discrete variable.
///
/// Panels are arranged into a grid of `ncol` columns (or `nrow` rows when
/// `ncol` is `none`). Only shared scales are supported in v1.
///
/// @category Facets
/// @stability stable
/// @since 0.1.0
///
/// @param var Name of the discrete column whose levels drive the panels.
/// @param ncol Number of columns in the panel grid, or `none` for automatic.
/// @param nrow Number of rows in the panel grid, or `none` for automatic.
/// @param scales Scale policy. Only `"fixed"` is supported in v1.
///
/// @returns Facet dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 12cm
/// //| height: 7cm
/// #let d = ()
/// #for sp in ("a", "b", "c") {
///   for i in range(0, 6) {
///     d.push((sp: sp, x: i, y: i + calc.rem(i, 3)))
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   facet: facet-wrap("sp", ncol: 3),
/// )
/// ```
///
/// @see @facet-grid, @plot
#let facet-wrap(var, ncol: none, nrow: none, scales: "fixed") = {
  if scales != "fixed" {
    panic("facet-wrap currently supports scales: \"fixed\" only")
  }
  (
    kind: "facet",
    facet: "wrap",
    var: var,
    ncol: ncol,
    nrow: nrow,
    scales: scales,
  )
}

#let levels-for(prepared, var) = shared.levels-for(prepared, var)

#let filter-layers(prepared, var, value) = shared.filter-layers-multi(
  prepared,
  ((var, value),),
)
