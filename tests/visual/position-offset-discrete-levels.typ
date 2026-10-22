// Numeric-offset positions over a discrete axis place each mark on the slot
// its level holds on the trained scale, not on the layer's own level order.
//
// Each cloud of points must sit over the box of its own level:
//   1. `limits` reorder the axis to c, a, b; beeswarm points follow.
//   2. The boxplot adds level a, which the jittered layer does not hold; the
//      jittered b and c points stay over the b and c boxes.
//   3. Jitterdodge under the same reordered limits: each level's two dodged
//      clouds stay over that level's box.

#import "../../lib.typ": *

#let data = range(45).map(i => (
  g: ("a", "b", "c").at(calc.rem(i, 3)),
  v: calc.rem(i * 7, 11) + 20 * calc.rem(i, 3),
  k: if calc.rem(i, 2) == 0 { "u" } else { "w" },
))

#let panel(points, position, ..extra) = plot(
  data: data,
  mapping: aes(x: "g", y: "v"),
  layers: (
    geom-boxplot(),
    geom-point(data: points, position: position, colour: red),
  ),
  ..extra,
  width: 7cm,
  height: 4cm,
)

#stack(
  dir: ttb,
  spacing: 0.6cm,
  panel(
    data,
    position-beeswarm(),
    scales: scales(x: scale-discrete(limits: ("c", "a", "b"))),
  ),
  panel(data.filter(r => r.g != "a"), position-jitter(seed: 1, height: 0)),
  plot(
    data: data,
    mapping: aes(x: "g", y: "v"),
    layers: (
      geom-boxplot(),
      geom-point(
        mapping: aes(colour: "k"),
        position: position-jitterdodge(seed: 1, height: 0),
      ),
    ),
    scales: scales(x: scale-discrete(limits: ("c", "a", "b"))),
    width: 7cm,
    height: 4cm,
  ),
)
