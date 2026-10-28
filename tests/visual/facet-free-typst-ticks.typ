// Free facet scales keep `typst()` markup on tick labels.
//
// Both panels map x through `typst("g")`. The left panel uses fixed scales and
// the right panel free scales. Both must show the evaluated symbols alpha and beta.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (g: "$alpha$", v: 1, f: "p"),
  (g: "$beta$", v: 2, f: "q"),
)

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..("fixed", "free_x").map(s => plot(
    data: d,
    mapping: aes(x: typst("g"), y: "v"),
    layers: (geom-point(),),
    facet: facet-wrap("f", scales: s),
    width: 7cm,
    height: 3.5cm,
  )),
)
