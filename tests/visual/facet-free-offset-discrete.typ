// Free facet scales over a discrete axis moved by a numeric-offset position.
//
// Five plots over the same data. Facet p holds level a, facet q holds b and c.
// Every panel must show a discrete x axis with only its own level names, and
// each cloud of points must sit over its own level:
//   1. geom-point with no position (the reference).
//   2. position-beeswarm.
//   3. position-jitter.
//   4. position-nudge.
//   5. position-beeswarm under facet-grid(scales: "free_x").

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let data = range(60).map(i => {
  let g = ("a", "b", "c").at(calc.rem(i, 3))
  (
    g: g,
    v: calc.rem(i * 7, 11) + 20 * calc.rem(i, 3),
    f: if g == "a" { "p" } else { "q" },
  )
})

#let faceted(layer, facet: facet-wrap("f", scales: "free_x")) = plot(
  data: data,
  mapping: aes(x: "g", y: "v"),
  layers: (layer,),
  facet: facet,
  width: 7cm,
  height: 4cm,
)

#stack(
  dir: ttb,
  spacing: 0.6cm,
  faceted(geom-point()),
  faceted(geom-point(position: position-beeswarm())),
  faceted(geom-point(position: position-jitter(seed: 1))),
  faceted(geom-point(position: position-nudge(x: 0.1))),
  faceted(
    geom-point(position: position-beeswarm()),
    facet: facet-grid(columns: "f", scales: "free_x"),
  ),
)
