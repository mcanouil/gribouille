// Benchmark case: geom-col. One bar per row, so cost scales linearly with the
// row count `n` injected via `--input n=<count>`.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let d = range(0, n).map(i => {
  let t = i / n
  (x: i, y: calc.abs(calc.sin(t * 6 * calc.pi)) + 0.2)
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-col(),),
  width: 12cm,
  height: 7cm,
)
