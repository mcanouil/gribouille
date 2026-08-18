// A discrete axis draws gridlines only when the theme asks for them: the first
// plot has none, the second has one line per level.

#import "../../lib.typ": *

#let d = (
  (g: "a", y: 3),
  (g: "b", y: 5),
  (g: "c", y: 2),
  (g: "d", y: 4),
)

#plot(
  data: d,
  mapping: aes(x: "g", y: "y"),
  layers: (geom-col(),),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: d,
  mapping: aes(x: "g", y: "y"),
  layers: (geom-col(),),
  theme: theme-minimal(panel-grid-major-x: element-line(
    colour: rgb("#cc0000"),
  )),
  width: 10cm,
  height: 6cm,
)
