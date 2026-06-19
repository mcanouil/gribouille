// Q-Q plots against three reference distributions: normal, uniform, exponential.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let _lcg(seed) = {
  calc.rem(seed * 1103515245 + 12345, 2147483648)
}

#let _draw-normal(n) = {
  let seed = 1234567
  let out = ()
  let i = 0
  while i < n {
    let acc = 0.0
    let j = 0
    while j < 12 {
      seed = _lcg(seed)
      acc = acc + seed / 2147483648
      j = j + 1
    }
    out.push((v: acc - 6.0))
    i = i + 1
  }
  out
}

#let _draw-uniform(n) = {
  let seed = 2468013
  let out = ()
  let i = 0
  while i < n {
    seed = _lcg(seed)
    out.push((v: seed / 2147483648))
    i = i + 1
  }
  out
}

#let _draw-exponential(n) = {
  let seed = 9876543
  let out = ()
  let i = 0
  while i < n {
    seed = _lcg(seed)
    let u = (seed + 1) / 2147483649
    out.push((v: -calc.ln(1 - u)))
    i = i + 1
  }
  out
}

#let panel(title, data, dist, x-name) = plot(
  data: data,
  mapping: aes(y: "v"),
  layers: (
    geom-qq-line(stroke: 0.8pt, distribution: dist),
    geom-qq(size: 2pt, alpha: 0.85, distribution: dist),
  ),
  labels: labels(title: title, x: x-name, y: "Sample Quantile"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  panel("normal", _draw-normal(80), "normal", "Normal quantile"),
  panel("uniform", _draw-uniform(80), "uniform", "Uniform quantile"),
  panel(
    "exponential",
    _draw-exponential(80),
    "exponential",
    "Exponential quantile",
  ),
)
