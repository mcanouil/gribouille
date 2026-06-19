// Q-Q plot: 80 normal-ish samples (sum of 12 uniforms) against standard-normal quantiles.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

// Linear-congruential generator: 80 normal-ish draws via the sum of 12
// uniforms minus 6. Seeded for reproducibility.
#let _draw-samples(n) = {
  let seed = 1234567
  let out = ()
  let i = 0
  while i < n {
    let acc = 0.0
    let j = 0
    while j < 12 {
      seed = calc.rem(seed * 1103515245 + 12345, 2147483648)
      acc = acc + seed / 2147483648
      j = j + 1
    }
    out.push((v: acc - 6.0))
    i = i + 1
  }
  out
}

#plot(
  data: _draw-samples(80),
  mapping: aes(y: "v"),
  layers: (
    geom-qq-line(stroke: 0.8pt),
    geom-qq(size: 2.5pt, alpha: 0.85),
  ),
  labels: labels(
    title: "Normal Q-Q Plot of 80 Simulated Samples",
    subtitle: "Points hug the IQR-fitted line, indicating the sample is approximately normal",
    x: "Theoretical Quantile",
    y: "Sample Quantile",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
