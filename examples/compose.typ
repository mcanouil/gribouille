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

= `collect: none` keeps each plot's legend in place

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "grid",
  columns: 2,
  collect: none,
)

= `collect: auto` (default) hoists every aesthetic identical across panels

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "grid",
  columns: 2,
)

= `collect: ("colour",)` hoists colour only; per-plot `size` ladders stay

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"), size: "hp")),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"), size: "wt")),
  layout: "grid",
  columns: 2,
  collect: ("colour",),
)

= Mismatched legends never hoist (`colour` keys differ across panels)

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: "hp")),
  layout: "grid",
  columns: 2,
)

= Shared legend on the left via `guides(default: ...)`

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "grid",
  columns: 2,
  guides: guides(default: guide-legend(position: "left")),
)

= Shared legend on top (laid out horizontally above the panels)

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "grid",
  columns: 2,
  guides: guides(default: guide-legend(position: "top")),
)

= Shared legend on the bottom

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "grid",
  columns: 2,
  guides: guides(default: guide-legend(position: "bottom")),
)

= Composition title and caption via `labs`

#box(width: 14cm, height: 5cm, compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "grid",
  columns: 2,
  labs: labs(title: "Fuel economy", caption: "Source: mtcars"),
))

= Vertical stack with shared legend on the right (`layout: "stack"`)

#compose(
  panel(aes(x: "wt", y: "mpg", colour: as-factor("cyl"))),
  panel(aes(x: "hp", y: "mpg", colour: as-factor("cyl"))),
  layout: "stack",
  direction: ttb,
)
