// Benchmark case: geom-boxplot. The `n` input rows are spread across eight
// discrete groups and reduced to a five-number summary per group, so the stat
// transform dominates while rendered elements stay bounded.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let groups = 8
#let d = range(0, n).map(i => {
  let g = calc.rem(i, groups)
  let t = i / n
  (group: "g" + str(g), value: calc.sin(t * 6 * calc.pi) + g * 0.5)
})

#plot(
  data: d,
  mapping: aes(x: "group", y: "value", fill: "group"),
  layers: (geom-boxplot(),),
  guides: guides(fill: none),
  width: 12cm,
  height: 7cm,
)
