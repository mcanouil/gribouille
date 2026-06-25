// Benchmark case: geom-line. One vertex per row joined into a single path, so
// cost scales linearly with the element count `n` injected via `--input n=<count>`.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let d = range(0, n).map(i => {
  let t = i / n
  let theta = t * 6 * calc.pi
  (x: t * 12, y: calc.sin(theta) * (1 + t) + t * 2)
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-line(stroke: 0.6pt),),
  width: 12cm,
  height: 7cm,
)
