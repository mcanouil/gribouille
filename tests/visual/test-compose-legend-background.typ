// legend-background on the hoisted, shared legend of a `compose()`.
//
// The standalone legend canvas is sized by `standalone-size`, which adds the
// painted `inset` and the reserved `outset` to the guide bbox. The stroked
// rect should be whole on every hoisted side; before the fix `clip: true` cut
// the border off.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a"),
  (x: 2, y: 2, g: "b"),
  (x: 3, y: 3, g: "c"),
)

#let themed = theme(
  legend-background: element-rect(
    fill: rgb("#e6f4ea"),
    colour: rgb("#2e7d4a"),
    stroke: 0.4pt,
    inset: margin(
      top: 0.15cm,
      right: 0.15cm,
      bottom: 0.15cm,
      left: 0.15cm,
    ),
    outset: margin(
      top: 0.1cm,
      right: 0.1cm,
      bottom: 0.1cm,
      left: 0.1cm,
    ),
  ),
)

#let panel(title) = defer(
  plot,
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt),),
  labels: labels(title: title),
)

#let composition(pos) = compose(
  panel("one"),
  panel("two"),
  columns: 2,
  guides: guides(colour: guide-legend(position: pos)),
  labels: labels(title: "hoisted " + pos),
  theme: themed,
  width: 12cm,
  height: 5cm,
)

#stack(
  dir: ttb,
  spacing: 0.8cm,
  composition("right"),
  composition("left"),
  composition("top"),
  composition("bottom"),
)
