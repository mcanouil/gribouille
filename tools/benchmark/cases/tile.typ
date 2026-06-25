// Benchmark case: geom-tile. One filled rectangle per row laid out on a near-
// square grid, so cost scales linearly with the element count `n` injected via
// `--input n=<count>`.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let side = calc.max(1, calc.ceil(calc.sqrt(n)))
#let d = range(0, n).map(i => {
  let gx = calc.rem(i, side)
  let gy = calc.quo(i, side)
  (x: gx, y: gy, fill: calc.sin(gx / 3) * calc.cos(gy / 3))
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", fill: "fill"),
  layers: (geom-tile(),),
  scales: (scale-fill-viridis-c(option: "viridis"),),
  width: 12cm,
  height: 9cm,
)
