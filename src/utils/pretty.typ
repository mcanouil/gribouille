// Pretty axis breaks, inspired by R's base pretty().
// Picks breaks of the form c * 10^k for c in {1, 2, 5}.

#let pretty(lo, hi, n: 5) = {
  if lo == hi {
    let step = if lo == 0 { 1.0 } else { calc.abs(lo) * 0.1 }
    return (lo - step, lo, lo + step)
  }
  let (lo, hi) = if lo > hi { (hi, lo) } else { (lo, hi) }
  let raw-step = (hi - lo) / n
  let exponent = calc.floor(calc.log(raw-step, base: 10))
  let mag = calc.pow(10.0, exponent)
  let r = raw-step / mag
  let nice = if r < 1.5 { 1.0 }
    else if r < 3.5 { 2.0 }
    else if r < 7.5 { 5.0 }
    else { 10.0 }
  let step = nice * mag
  let start = calc.floor(lo / step) * step
  let tol = step * 1e-6
  let breaks = ()
  let b = start
  while b <= hi + tol {
    if b >= lo - tol {
      breaks.push(b)
    }
    b = b + step
  }
  breaks
}
