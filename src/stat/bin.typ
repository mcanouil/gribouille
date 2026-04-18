///! Uniform-width histogram binning.
///!
///! Backing statistic for @geom-histogram. Emits one row per bin with the
///! bin midpoint as x, the count as y, and the bin `width` for reference.

#import "../utils/types.typ": parse-number

/// Bin statistic: partition x into uniform-width bins, count rows per bin.
///
/// Either `bins` or `binwidth` fixes the partition; if both are supplied,
/// `binwidth` wins.
///
/// @category Stats
/// @stability stable
/// @since 0.1.0
///
/// @param bins Target number of bins when `binwidth` is `none`.
/// @param binwidth Fixed bin width. Overrides `bins` when set.
///
/// @returns Statistic object with `name: "bin"`, consumed by geom layers.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 40).map(i => (x: i * 0.25))
/// #plot(
///   data: d,
///   mapping: aes(x: "x"),
///   layers: (geom-histogram(bins: 8),),
/// )
/// ```
///
/// @see @geom-histogram, @stat-count
#let stat-bin(bins: 30, binwidth: none) = (
  kind: "stat",
  name: "bin",
  params: (bins: bins, binwidth: binwidth),
)

#let apply(data, mapping, params: (:)) = {
  let x-col = if mapping != none { mapping.at("x", default: none) } else { none }
  if x-col == none { return (data: data, mapping: mapping) }
  let xs = data.map(r => parse-number(r.at(x-col, default: none))).filter(v => v != none)
  if xs.len() == 0 { return (data: (), mapping: (x: "x", y: "y")) }
  let lo = calc.min(..xs)
  let hi = calc.max(..xs)
  if hi == lo { hi = lo + 1.0 }
  let binwidth = params.at("binwidth", default: none)
  let bins = params.at("bins", default: 30)
  let n-bins = if binwidth != none and binwidth > 0 {
    calc.max(1, int(calc.ceil((hi - lo) / binwidth)))
  } else {
    bins
  }
  let width = (hi - lo) / n-bins
  let counts = range(n-bins).map(_ => 0)
  for v in xs {
    let raw = int(calc.floor((v - lo) / width))
    let idx = calc.max(0, calc.min(n-bins - 1, raw))
    counts.at(idx) = counts.at(idx) + 1
  }
  let rows = range(n-bins).map(i => (
    x: lo + (i + 0.5) * width,
    y: counts.at(i),
    width: width,
  ))
  (data: rows, mapping: (x: "x", y: "y"))
}
