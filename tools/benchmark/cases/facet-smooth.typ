// Benchmark case: facet-wrap + geom-smooth. The `n` rows are split across four
// panels and the linear smoother re-trains per panel, exposing the per-panel
// stat re-training cost on top of the per-row point layer.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let d = range(0, n).map(i => {
  let p = calc.rem(i, 4)
  let t = i / n
  (
    x: t * 12,
    y: calc.sin(t * 6 * calc.pi) + t * 3 + p,
    panel: "p" + str(p),
  )
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 1.5pt, alpha: 0.5),
    geom-smooth(method: "lm"),
  ),
  facet: facet-wrap("panel", ncolumn: 2),
  width: 12cm,
  height: 9cm,
)
