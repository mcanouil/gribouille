#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 0cm)

#let mtcars = (
  (mpg: 21.0, wt: 2.620, hp: 110, cyl: "6"),
  (mpg: 22.8, wt: 2.320, hp: 93, cyl: "4"),
  (mpg: 18.7, wt: 3.440, hp: 175, cyl: "8"),
  (mpg: 16.4, wt: 4.070, hp: 205, cyl: "8"),
  (mpg: 33.9, wt: 1.835, hp: 113, cyl: "4"),
  (mpg: 21.4, wt: 3.215, hp: 110, cyl: "6"),
)

#let panel(mapping) = plot(
  data: mtcars,
  mapping: mapping,
  layers: (geom-point(),),
  width: 6cm,
  height: 4cm,
  defer: true,
)

// Gallery showcase: a single squared two-by-two composition with a shared
// colour legend, panel tags, and a composition title. The full set of
// `collect` / legend-placement / `labs` / stack variations lives in the
// typstdoc `@examples` on the reference page.
#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "wt", y: "hp", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "wt", colour: as-factor("cyl"))),
  columns: 2,
  tag-levels: "A",
  tag-prefix: "(",
  tag-suffix: ")",
  labs: labs(title: "Motor Trend road tests", caption: "Source: mtcars"),
  width: 13cm,
  height: 10cm,
)
