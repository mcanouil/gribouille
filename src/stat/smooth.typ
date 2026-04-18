///! Smoother statistic backing @geom-smooth.
///!
///! v1 supports `method: "lm"` only (closed-form OLS). Emits a dense grid of
///! `(x, y, ymin, ymax)` for the fitted line and pointwise confidence band.

#import "../utils/types.typ": parse-number

/// Smoother statistic: closed-form linear fit with a pointwise confidence band.
///
/// Returns a dense grid of `(x, y, ymin, ymax)` rows where `y` is the fitted
/// value and `ymin`/`ymax` bound a pointwise confidence band.
///
/// @category Stats
/// @stability stable
/// @since 0.1.0
///
/// @param method Smoother method. `"lm"` is the only supported value in v1.
/// @param se Whether to compute the confidence band. When `false`, `ymin == ymax == y`.
/// @param level Confidence level for the band (e.g. `0.95`).
///
/// @returns Statistic object with `name: "smooth"`, consumed by geom layers.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 20).map(i => (
///   x: i,
///   y: i * 0.5 + calc.sin(i * 0.4) * 2,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 2pt),
///     geom-smooth(method: "lm"),
///   ),
/// )
/// ```
///
/// @see @geom-smooth, @stat-identity
#let stat-smooth(method: "lm", se: true, level: 0.95) = (
  kind: "stat",
  name: "smooth",
  params: (method: method, se: se, level: level),
)

#let _sum(xs) = {
  let acc = 0.0
  for v in xs { acc = acc + v }
  acc
}

#let apply(data, mapping, params: (:)) = {
  let x-col = if mapping != none { mapping.at("x", default: none) } else { none }
  let y-col = if mapping != none { mapping.at("y", default: none) } else { none }
  let empty = (data: (), mapping: (x: "x", y: "y", ymin: "ymin", ymax: "ymax"))
  if x-col == none or y-col == none { return empty }
  let pairs = data.map(r => (
    x: parse-number(r.at(x-col, default: none)),
    y: parse-number(r.at(y-col, default: none)),
  )).filter(p => p.x != none and p.y != none)
  let n = pairs.len()
  if n < 2 { return empty }
  let xs = pairs.map(p => p.x)
  let ys = pairs.map(p => p.y)
  let x-mean = _sum(xs) / n
  let y-mean = _sum(ys) / n
  let sxx = _sum(pairs.map(p => (p.x - x-mean) * (p.x - x-mean)))
  let sxy = _sum(pairs.map(p => (p.x - x-mean) * (p.y - y-mean)))
  if sxx == 0 { return empty }
  let slope = sxy / sxx
  let intercept = y-mean - slope * x-mean
  let rss = _sum(pairs.map(p => {
    let resid = p.y - (intercept + slope * p.x)
    resid * resid
  }))
  let dof = calc.max(1, n - 2)
  let sigma2 = rss / dof
  let x-min = calc.min(..xs)
  let x-max = calc.max(..xs)
  let steps = 80
  let se-on = params.at("se", default: true)
  let t-val = 1.96
  let rows = range(steps + 1).map(i => {
    let t = i / steps
    let x = x-min + t * (x-max - x-min)
    let y-hat = intercept + slope * x
    let se = if se-on {
      let var = sigma2 * (1.0 / n + (x - x-mean) * (x - x-mean) / sxx)
      calc.sqrt(calc.max(0.0, var))
    } else { 0.0 }
    let margin = t-val * se
    (x: x, y: y-hat, ymin: y-hat - margin, ymax: y-hat + margin)
  })
  (data: rows, mapping: (x: "x", y: "y", ymin: "ymin", ymax: "ymax"))
}
