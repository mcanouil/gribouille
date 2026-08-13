///! Hexagonal two-dimensional binning. Backing statistic for \@geom-hex.

#import "../utils/aes-resolve.typ": stat-output-mapping
#import "../utils/hex.typ": hex-cells, panel-hex-grid

/// Two-dimensional hexagonal bin statistic: partition (x, y) into a
/// pointy-top hex grid and count rows per cell.
///
/// `bins` and `binwidth` accept either a scalar or an `(x, y)` pair.
///
/// \@category Stats
/// \@subcategory Binning
/// \@stability stable
///
/// \@param bins Scalar or `(x, y)` pair — target bin counts.
///
/// \@param binwidth Scalar or `(x, y)` pair — fixed pitches.
///
/// \@returns Statistic object with `name: "bin-hex"`.
///
/// \@examples `stat-bin-hex` powers `geom-hex`; pass `bins` (or `binwidth`)
/// through the wrapper to bin a noisy scatter onto a 20-bin hex grid
/// coloured by count.
/// ```
/// //| alt: "Hexagonal bin grid of sine/cosine samples with 20 hex cells per axis shaded by count via geom-hex backed by stat-bin-hex and the viridis fill palette."
/// #let d = range(0, 400).map(i => (
///   x: calc.sin(i * 0.13) * 4,
///   y: calc.cos(i * 0.21) * 4,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-hex(bins: 20),),
///   scales: scales(fill: scale-viridis-c()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@geom-hex, \@stat-bin-2d
#let stat-bin-hex(bins: 30, binwidth: none) = (
  kind: "stat",
  name: "bin-hex",
  params: (bins: bins, binwidth: binwidth),
)

#let apply(data, mapping, params: (:)) = {
  let new-mapping = stat-output-mapping(
    mapping,
    (x: "x", y: "y", fill: "_count"),
  )
  if mapping == none { return (data: (), mapping: new-mapping) }
  let result = hex-cells(
    data,
    mapping.at("x", default: none),
    mapping.at("y", default: none),
    params,
    weight-col: mapping.at("weight", default: none),
  )
  if result == none { return (data: (), mapping: new-mapping) }
  let grid = result.grid
  // `_density` is the cell's fraction of the total count, `count / sum(count)`.
  // The guard keeps the division safe when every
  // occupied cell carries zero weight.
  let cells = result.cells.values()
  let total = cells.map(c => c.count).sum(default: 0)
  let denom = if total == 0 { 1 } else { total }
  let rows = cells.map(c => (
    x: c.cx,
    y: c.cy,
    _count: c.count,
    _density: c.count / denom,
    _hex-dx: grid.dx,
    _hex-dy: grid.dy,
  ))
  (data: rows, mapping: new-mapping)
}
