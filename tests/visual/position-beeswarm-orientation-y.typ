// `position-beeswarm(orientation: "y")` spreads points up and down.
//
// Two panels:
//   1. A continuous x with a discrete y of three levels. Each level holds a
//      swarm that spreads vertically around its own tick, wider where the x
//      values are dense. The default `auto` picks the y orientation.
//   2. A continuous x with a constant `y: 0` and `orientation: "y"`. The points
//      spread above and below the line y = 0 as one swarm.

#import "../../lib.typ": *

#let data = range(60).map(i => (
  g: ("a", "b", "c").at(calc.rem(i, 3)),
  v: calc.rem(i * 7, 11) + 6 * calc.rem(i, 3),
))
#let flat = data.map(r => (v: r.v, y: 0))

#stack(
  dir: ttb,
  spacing: 0.6cm,
  plot(
    data: data,
    mapping: aes(x: "v", y: "g"),
    layers: (geom-point(position: position-beeswarm(width: 0.35)),),
    width: 8cm,
    height: 5cm,
  ),
  plot(
    data: flat,
    mapping: aes(x: "v", y: "y"),
    layers: (
      geom-point(position: position-beeswarm(width: 0.35, orientation: "y")),
    ),
    width: 8cm,
    height: 4cm,
  ),
)
