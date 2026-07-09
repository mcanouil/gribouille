// stat-quantile: linear quantile regression at user-supplied tau.

#import "../../src/stat/quantile.typ": apply, stat-quantile

#let s = stat-quantile()
#assert.eq(s.kind, "stat")
#assert.eq(s.name, "quantile")
#assert.eq(s.params.quantiles, (0.25, 0.5, 0.75))
#assert.eq(s.params.n-samples, 64)

#let s2 = stat-quantile(quantiles: (0.1, 0.9), n-samples: 32)
#assert.eq(s2.params.quantiles, (0.1, 0.9))
#assert.eq(s2.params.n-samples, 32)

// Collinear data y = 2x + 1: every pair has slope 2, so the single
// candidate slope yields the exact line with zero loss. All quantile fits
// coincide.
#let data = range(0, 5).map(i => (x: i, y: 2 * i + 1))
#let r = apply(
  data,
  (x: "x", y: "y"),
  params: (quantiles: (0.5,), n-samples: 4),
)

#assert.eq(r.mapping.x, "x")
#assert.eq(r.mapping.y, "y")
#assert.eq(r.mapping.group, "group")
// 5 samples (n-samples + 1) for a single tau.
#assert.eq(r.data.len(), 5)

// Endpoints: x=0 → y=1; x=4 → y=9.
#assert.eq(r.data.first().x, 0)
#assert.eq(r.data.first().y, 1)
#assert.eq(r.data.last().x, 4)
#assert.eq(r.data.last().y, 9)

// Group key reflects tau.
#assert.eq(r.data.first().group, "q0.5")
#assert.eq(r.data.first()._quantile, 0.5)

// Three quantiles → three groups → 3 * (n-samples + 1) rows.
#let r3 = apply(
  data,
  (x: "x", y: "y"),
  params: (quantiles: (0.25, 0.5, 0.75), n-samples: 4),
)
#assert.eq(r3.data.len(), 15)

// Shifted-y test: with the median, the line fits y = 2x + 1 exactly.
#let mid = r.data.at(2)
#assert.eq(mid.x, 2)
#assert.eq(mid.y, 5)

// Noisy linear cloud. References from R `quantreg::rq(y ~ x, tau)`:
//   tau = 0.25 -> intercept = 0, slope = 0.98   (line through (0,0)-(5,4.9))
//   tau = 0.50 -> intercept = 0, slope = 1.0    (line through (0,0)-(1,1))
//   tau = 0.75 -> intercept = 0, slope = 1.025  (line through (0,0)-(4,4.1))
#let close-q(a, b) = calc.abs(a - b) < 1e-9
#let noisy = (
  (x: 0, y: 0.0),
  (x: 1, y: 1.0),
  (x: 2, y: 1.8),
  (x: 3, y: 3.2),
  (x: 4, y: 4.1),
  (x: 5, y: 4.9),
  (x: 6, y: 6.0),
)
#let r-noisy = apply(
  noisy,
  (x: "x", y: "y"),
  params: (quantiles: (0.25, 0.5, 0.75), n-samples: 2),
)
// 3 quantiles * (n-samples + 1) rows.
#assert.eq(r-noisy.data.len(), 9)

// Per-tau slope from the first and last sampled points (x = 0 and x = 6).
#let line-of(rows, tau) = {
  let pts = rows.filter(p => p._quantile == tau)
  let lo = pts.first()
  let hi = pts.last()
  let slope = (hi.y - lo.y) / (hi.x - lo.x)
  (intercept: lo.y - slope * lo.x, slope: slope)
}

#let f25 = line-of(r-noisy.data, 0.25)
#assert(close-q(f25.intercept, 0.0))
#assert(close-q(f25.slope, 0.98))

#let f50 = line-of(r-noisy.data, 0.5)
#assert(close-q(f50.intercept, 0.0))
#assert(close-q(f50.slope, 1.0))

#let f75 = line-of(r-noisy.data, 0.75)
#assert(close-q(f75.intercept, 0.0))
#assert(close-q(f75.slope, 1.025))

// Slopes should rise monotonically through the central tau range on a
// roughly linear cloud.
#assert(f25.slope < f50.slope)
#assert(f50.slope < f75.slope)

// ---------------------------------------------------------------------------
// Oracle comparison: the retired O(n³) pair enumerator, kept here as the
// reference implementation the breakpoint search must reproduce.
#let oracle-fit(pairs, taus) = {
  let n = pairs.len()
  let fallback = if n > 0 { pairs.first().y } else { 0.0 }
  let best = taus.map(_ => (intercept: fallback, slope: 0.0, loss: none))
  let k-count = taus.len()
  let i = 0
  while i < n {
    let pi = pairs.at(i)
    let j = i + 1
    while j < n {
      let pj = pairs.at(j)
      let dx = pj.x - pi.x
      if dx != 0 {
        let slope = (pj.y - pi.y) / dx
        let intercept = pi.y - slope * pi.x
        let losses = taus.map(_ => 0.0)
        for p in pairs {
          let r = p.y - (intercept + slope * p.x)
          let neg = r < 0
          let k = 0
          while k < k-count {
            let tau = taus.at(k)
            let weight = if neg { tau - 1.0 } else { tau }
            losses.at(k) = losses.at(k) + r * weight
            k = k + 1
          }
        }
        let k = 0
        while k < k-count {
          if best.at(k).loss == none or losses.at(k) < best.at(k).loss {
            best.at(k) = (
              intercept: intercept,
              slope: slope,
              loss: losses.at(k),
            )
          }
          k = k + 1
        }
      }
      j = j + 1
    }
    i = i + 1
  }
  best
}

#import "../../src/stat/quantile.typ": _fit-quantiles, _loss-line

#let close(a, b, tol) = calc.abs(a - b) <= tol

// Deterministic 25-point cloud across a τ sweep. Distinct vertex lines can
// tie in loss at f64 resolution (τ = 0.1 here does), so the contract is
// mutual loss equality: the solver never fits worse than the oracle and
// never claims a loss the oracle cannot reach.
#let cloud = range(0, 25).map(i => (
  x: i / 3,
  y: 0.7 * i / 3 + calc.sin(i * 1.3) + 0.4 * calc.cos(i * 2.7),
))
#let sweep = (0.1, 0.25, 0.5, 0.75, 0.9)
#let got = _fit-quantiles(cloud, sweep)
#let want = oracle-fit(cloud, sweep)
#for k in range(sweep.len()) {
  let scale = calc.max(calc.abs(want.at(k).loss), 1.0)
  assert(
    close(got.at(k).loss, want.at(k).loss, 1e-12 * scale),
    message: "cloud loss tau " + str(sweep.at(k)),
  )
  assert(
    got.at(k).loss <= want.at(k).loss + 1e-15 * scale,
    message: "cloud solver worse than oracle at tau " + str(sweep.at(k)),
  )
}

// Integer τ·n (n = 8, τ = 0.25 / 0.5): the intercept quantile is an
// interval, so only the loss is pinned (accepted behavioural delta).
#let eight = range(0, 8).map(i => (
  x: i,
  y: 1.5 * i + calc.rem(i * 5, 3) - 1,
))
#for tau in (0.25, 0.5) {
  let g = _fit-quantiles(eight, (tau,)).first()
  let w = oracle-fit(eight, (tau,)).first()
  let scale = calc.max(calc.abs(w.loss), 1.0)
  assert(
    close(g.loss, w.loss, 1e-12 * scale),
    message: "integer tau*n loss tau " + str(tau),
  )
}

// Flat optimum: symmetric band, τ = 0.5 — an interval of optimal lines.
// Loss equality is required; the specific line may differ from the oracle.
#let band = ((x: 0, y: -1), (x: 0.5, y: 1), (x: 1, y: -1), (x: 1.5, y: 1))
#let g-band = _fit-quantiles(band, (0.5,)).first()
#let w-band = oracle-fit(band, (0.5,)).first()
#assert(close(g-band.loss, w-band.loss, 1e-12), message: "flat optimum loss")

// n = 2: single candidate slope, exact interpolation for every τ.
#let two = ((x: 0, y: 3), (x: 2, y: 7))
#for tau in (0.1, 0.5, 0.9) {
  let g = _fit-quantiles(two, (tau,)).first()
  assert(close(g.slope, 2.0, 1e-12), message: "n=2 slope")
  assert(close(g.intercept, 3.0, 1e-12), message: "n=2 intercept")
}

// Repeated x values (vertical pairs are skipped as candidates) and exact
// duplicate points (slope dedupe path).
#let vertical = (
  (x: 0, y: 0),
  (x: 0, y: 2),
  (x: 1, y: 1),
  (x: 1, y: 1),
  (x: 2, y: 2),
)
#let g-v = _fit-quantiles(vertical, (0.5,)).first()
#let w-v = oracle-fit(vertical, (0.5,)).first()
#assert(close(g-v.loss, w-v.loss, 1e-12), message: "repeated-x loss")

// Extreme τ exercises the k-clamp; float-nasty τ·n (0.3 · 10 = 2.999…).
#let ten = range(0, 10).map(i => (x: i, y: 2 * i + calc.rem(i * 7, 5)))
#for tau in (0.01, 0.3, 0.99) {
  let g = _fit-quantiles(ten, (tau,)).first()
  let w = oracle-fit(ten, (tau,)).first()
  let scale = calc.max(calc.abs(w.loss), 1.0)
  assert(
    close(g.loss, w.loss, 1e-12 * scale),
    message: "extreme tau loss " + str(tau),
  )
}

// Scale stress: huge x, tiny y — losses agree at relative tolerance.
#let stress = range(0, 12).map(i => (
  x: i * 1e6,
  y: 1e-3 * i + 1e-4 * calc.sin(i * 2.1),
))
#let g-s = _fit-quantiles(stress, (0.5,)).first()
#let w-s = oracle-fit(stress, (0.5,)).first()
#let s-scale = calc.max(calc.abs(w-s.loss), 1e-6)
#assert(close(g-s.loss, w-s.loss, 1e-9 * s-scale), message: "scale stress")

// All y equal: the flat line has zero loss.
#let flat = range(0, 6).map(i => (x: i, y: 4.0))
#let g-f = _fit-quantiles(flat, (0.5,)).first()
#assert(close(g-f.slope, 0.0, 1e-12), message: "flat slope")
#assert(close(g-f.intercept, 4.0, 1e-12), message: "flat intercept")
#assert(
  close(_loss-line(flat, 0.5, g-f.intercept, g-f.slope), 0.0, 1e-12),
  message: "flat loss",
)

stat-quantile tests passed.
