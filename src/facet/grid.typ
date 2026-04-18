///! Grid faceting.
///!
///! Panels arranged on a `row x col` grid, driven by two discrete variables.
///! v1 supports shared scales only.

/// Grid facets: panels on a row x col grid from two discrete variables.
///
/// Either `rows` or `cols` may be `none`, but not both. Only shared scales
/// are supported in v1.
///
/// @category Facets
/// @stability stable
/// @since 0.1.0
///
/// @param rows Name of the discrete column driving panel rows, or `none`.
/// @param cols Name of the discrete column driving panel columns, or `none`.
/// @param scales Scale policy. Only `"fixed"` is supported in v1.
///
/// @returns Facet dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 12cm
/// //| height: 7cm
/// #let d = ()
/// #for sp in ("a", "b") {
///   for sex in ("F", "M") {
///     for i in range(0, 5) {
///       d.push((sp: sp, sex: sex, x: i, y: i + 1))
///     }
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   facet: facet-grid(rows: "sex", cols: "sp"),
/// )
/// ```
///
/// @see @facet-wrap, @plot
#let facet-grid(rows: none, cols: none, scales: "fixed") = {
  if scales != "fixed" {
    panic("facet-grid currently supports scales: \"fixed\" only")
  }
  if rows == none and cols == none {
    panic("facet-grid needs at least one of rows: or cols:")
  }
  (
    kind: "facet",
    facet: "grid",
    rows: rows,
    cols: cols,
    scales: scales,
  )
}
