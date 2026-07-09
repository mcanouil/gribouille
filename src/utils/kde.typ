// Gaussian kernel density estimation shared by stat-density and
// stat-ydensity. Kernels are evaluated directly (O(pairs × n) per call),
// workable for plot-sized inputs.

#import "errors.typ": fail-type
#import "summaries.typ": quantile-type-7

// Grid extension beyond the data range, in bandwidths. Matches R's
// `density(..., cut = 3)` default for the Gaussian kernel.
#let _CUT = 3

// Silverman's rule of thumb (R's `bw.nrd0`): 0.9 times the lesser of the
// standard deviation and IQR/1.34, times n^(-1/5), with R's fallback chain
// when the spread estimate degenerates to zero.
#let bw-nrd0(values) = {
  let n = values.len()
  let mean = values.sum() / n
  let sd = calc.sqrt(
    values.map(v => (v - mean) * (v - mean)).sum() / (n - 1),
  )
  let sorted = values.sorted()
  let iqr = quantile-type-7(sorted, 0.75) - quantile-type-7(sorted, 0.25)
  let spread = calc.min(sd, iqr / 1.34)
  if spread == 0 { spread = sd }
  if spread == 0 { spread = calc.abs(values.first()) }
  if spread == 0 { spread = 1.0 }
  0.9 * spread * calc.pow(n, -0.2)
}

// Panic unless the shared KDE parameters are well-formed. `scope` names the
// calling stat so the message points at the user-facing constructor.
#let validate-kde-params(scope, params) = {
  let bw = params.at("bw", default: auto)
  if bw != auto and (type(bw) not in (int, float) or bw <= 0) {
    fail-type(scope, "bw", bw, "a positive number or `auto`")
  }
  let adjust = params.at("adjust", default: 1)
  if type(adjust) not in (int, float) or adjust <= 0 {
    fail-type(scope, "adjust", adjust, "a positive number")
  }
  let n = params.at("n", default: 512)
  if type(n) != int or n < 2 {
    fail-type(scope, "n", n, "an integer of at least 2")
  }
  let trim = params.at("trim", default: false)
  if type(trim) != bool {
    fail-type(scope, "trim", trim, "a boolean")
  }
}

// Weighted Gaussian KDE of `pairs` (dicts with numeric `x` and positive
// weight `w`; the caller filters) over `n` evenly spaced grid points. The
// grid spans the data range, extended by `_CUT` bandwidths per side unless
// `trim`. `bw: auto` applies `bw-nrd0`; `adjust` multiplies the bandwidth.
// Returns `(rows, bw)` where rows carry `(x: grid value, density:)`.
#let kde-1d(pairs, bw: auto, adjust: 1, n: 512, trim: false) = {
  let xs = pairs.map(p => p.x)
  let total-weight = pairs.map(p => p.w).sum()
  let resolved-bw = if bw == auto { bw-nrd0(xs) } else { float(bw) }
  resolved-bw = resolved-bw * adjust

  let x-lo = calc.min(..xs)
  let x-hi = calc.max(..xs)
  if not trim {
    x-lo -= _CUT * resolved-bw
    x-hi += _CUT * resolved-bw
  }
  let norm = 1 / (resolved-bw * calc.sqrt(2 * calc.pi))

  let rows = range(n).map(i => {
    let g = if x-hi == x-lo { x-lo } else {
      x-lo + (x-hi - x-lo) * i / (n - 1)
    }
    let density = (
      pairs
        .map(p => {
          let z = (g - p.x) / resolved-bw
          p.w * calc.exp(-0.5 * z * z)
        })
        .sum()
        * norm
        / total-weight
    )
    (x: g, density: density)
  })
  (rows: rows, bw: resolved-bw)
}
