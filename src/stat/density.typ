///! Gaussian kernel density estimate.
///!
///! Backing statistic for \@geom-density. Smooths the x sample into a dense
///! `(x, y)` density curve: each grid value is the weight-normalised sum of
///! Gaussian kernels centred on the observations, evaluated directly
///! (O(rows × n) per group, workable for plot-sized inputs).

#import "../utils/types.typ": parse-number
#import "../utils/summaries.typ": quantile-type-7, read-weight
#import "../utils/aes-resolve.typ": stat-output-mapping
#import "../utils/errors.typ": fail-range, fail-type

// Grid extension beyond the data range, in bandwidths. Matches R's
// `density(..., cut = 3)` default for the Gaussian kernel.
#let _CUT = 3

/// Density statistic: Gaussian kernel density estimate of the x sample.
///
/// Emits `n` evenly spaced `(x, y)` rows per group where `y` is the estimated
/// density, plus the after-stat columns `_density` (same as `y`), `_count`
/// (density scaled by the number of observations), `_scaled` (density scaled
/// to a maximum of 1), and `_n` (the number of observations).
///
/// \@category Stats
/// \@subcategory Distributions
/// \@stability stable
/// \@since 0.5.0
///
/// \@param bw Kernel bandwidth. `auto` applies Silverman's rule of thumb
/// (R's `bw.nrd0`); pass a positive number to fix it.
///
/// \@param adjust Bandwidth multiplier: the kernels use `adjust * bw`, so
/// `adjust: 0.5` halves the smoothing.
///
/// \@param n Number of evenly spaced grid points the density is evaluated at.
///
/// \@param trim Whether to restrict the grid to the data range. `false`
/// (default) extends it by three bandwidths on each side so the curve decays
/// to the baseline.
///
/// \@returns Statistic object with `name: "density"`, consumed by geom layers.
///
/// \@examples Density curve of a skewed sample via `geom-line(stat: "density")`.
/// ```
/// //| alt: "Density chart with x on the horizontal axis and estimated density on the vertical axis, a smooth right-skewed curve peaking near x = 2."
/// #let d = range(0, 60).map(i => (
///   x: calc.pow(calc.rem(i * 7, 30) / 10, 2) * 0.7 + 1,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x"),
///   layers: (geom-line(stat: "density", stroke: 1pt),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Constructor form: customise the smoothing with `adjust` on any
/// geom; here a coarser and a finer estimate of the same sample overlay.
/// ```
/// //| alt: "Two overlaid density curves of the same sample: a smooth wide curve with adjust 2 and a wigglier narrow curve with adjust 0.5, distinguished by linetype."
/// #let d = range(0, 60).map(i => (
///   x: calc.sin(i * 0.9) * 2 + calc.rem(i, 3),
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x"),
///   layers: (
///     geom-line(stat: stat-density(adjust: 2), stroke: 1pt),
///     geom-line(stat: stat-density(adjust: 0.5), stroke: 1pt, linetype: "dashed"),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@geom-density, \@stat-bin, \@stat-ecdf
#let stat-density(bw: auto, adjust: 1, n: 512, trim: false) = (
  kind: "stat",
  name: "density",
  params: (bw: bw, adjust: adjust, n: n, trim: trim),
)

// Silverman's rule of thumb (R's `bw.nrd0`): 0.9 times the lesser of the
// standard deviation and IQR/1.34, times n^(-1/5), with R's fallback chain
// when the spread estimate degenerates to zero.
#let _bw-nrd0(xs) = {
  let n = xs.len()
  let mean = xs.sum() / n
  let sd = calc.sqrt(
    xs.map(v => (v - mean) * (v - mean)).sum() / (n - 1),
  )
  let sorted = xs.sorted()
  let iqr = quantile-type-7(sorted, 0.75) - quantile-type-7(sorted, 0.25)
  let spread = calc.min(sd, iqr / 1.34)
  if spread == 0 { spread = sd }
  if spread == 0 { spread = calc.abs(xs.first()) }
  if spread == 0 { spread = 1.0 }
  0.9 * spread * calc.pow(n, -0.2)
}

#let _validate(params) = {
  let bw = params.at("bw", default: auto)
  if bw != auto and (type(bw) not in (int, float) or bw <= 0) {
    fail-type("stat-density", "bw", bw, "a positive number or `auto`")
  }
  let adjust = params.at("adjust", default: 1)
  if type(adjust) not in (int, float) or adjust <= 0 {
    fail-type("stat-density", "adjust", adjust, "a positive number")
  }
  let n = params.at("n", default: 512)
  if type(n) != int or n < 2 {
    fail-type("stat-density", "n", n, "an integer of at least 2")
  }
  let trim = params.at("trim", default: false)
  if type(trim) != bool {
    fail-type("stat-density", "trim", trim, "a boolean")
  }
}

#let apply(data, mapping, params: (:)) = {
  let x-col = if mapping != none { mapping.at("x", default: none) } else {
    none
  }
  let new-mapping = stat-output-mapping(mapping, (x: "x", y: "y"))
  if x-col == none { return (data: (), mapping: new-mapping) }
  _validate(params)
  let weight-col = mapping.at("weight", default: none)
  let pairs = data
    .map(r => {
      let xv = parse-number(r.at(x-col, default: none))
      if xv == none { return none }
      (x: xv, w: read-weight(r, weight-col))
    })
    .filter(p => p != none and p.w > 0)
  if pairs.len() < 2 { return (data: (), mapping: new-mapping) }

  let xs = pairs.map(p => p.x)
  let total-weight = pairs.map(p => p.w).sum()
  let bw-base = params.at("bw", default: auto)
  let bw = if bw-base == auto { _bw-nrd0(xs) } else { float(bw-base) }
  bw = bw * params.at("adjust", default: 1)

  let x-lo = calc.min(..xs)
  let x-hi = calc.max(..xs)
  if not params.at("trim", default: false) {
    x-lo -= _CUT * bw
    x-hi += _CUT * bw
  }
  let n-grid = params.at("n", default: 512)
  let n-obs = pairs.len()
  let norm = 1 / (bw * calc.sqrt(2 * calc.pi))

  let rows = range(n-grid).map(i => {
    let g = if x-hi == x-lo { x-lo } else {
      x-lo + (x-hi - x-lo) * i / (n-grid - 1)
    }
    let density = (
      pairs
        .map(p => {
          let z = (g - p.x) / bw
          p.w * calc.exp(-0.5 * z * z)
        })
        .sum()
        * norm
        / total-weight
    )
    (x: g, y: density, _density: density, _count: density * n-obs, _n: n-obs)
  })
  let peak = calc.max(..rows.map(r => r.y))
  let denom = if peak > 0 { peak } else { 1 }
  rows = rows.map(r => r + (_scaled: r.y / denom))
  (data: rows, mapping: new-mapping)
}
