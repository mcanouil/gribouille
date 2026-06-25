// Benchmark case: geom-bin-2d. The `n` input rows are aggregated into a fixed
// 25-by-25 grid, so rendered elements stay bounded by the bin count rather than
// `n`. Exposes the sublinear scaling regime against the per-row geoms.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let d = range(0, n).map(i => {
  let t = i / n
  let theta = t * 6 * calc.pi
  let r = 1 + t * 3 + calc.sin(theta * 2) * 0.4
  (
    x: r * calc.cos(theta) + calc.sin(t * 11.0) * 0.3,
    y: r * calc.sin(theta) + calc.cos(t * 13.0) * 0.3,
  )
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-bin-2d(bins: 25),),
  scales: (scale-fill-viridis-c(option: "magma"),),
  width: 12cm,
  height: 9cm,
)
