// Smoke render: position dodge shifts each group onto its own slot under
// coord-radial.
//
// With theta on x, the slots split each category's angular sweep. With theta
// on y, the slots split each category's ring. The error bars, points and
// ranges sit on the centre line of the column, box or crossbar of their group.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let summary = (
  (q: "A", grp: "a", y: 3, lo: 2, hi: 4),
  (q: "A", grp: "b", y: 5, lo: 4, hi: 6),
  (q: "B", grp: "a", y: 4, lo: 3, hi: 5),
  (q: "B", grp: "b", y: 2, lo: 1, hi: 3),
  (q: "C", grp: "a", y: 6, lo: 5, hi: 7),
  (q: "C", grp: "b", y: 4, lo: 3, hi: 5),
)

#let raw = (
  ("A", "B", "C")
    .map(q => ("a", "b").map(grp => range(9).map(i => (
      q: q,
      grp: grp,
      y: i + (if grp == "a" { 1 } else { 4 }) + (if q == "B" { 2 } else { 0 }),
    ))))
    .flatten()
)

#let ranges = aes(x: "q", y: "y", ymin: "lo", ymax: "hi", fill: "grp")
#let values = aes(x: "q", y: "y", fill: "grp")

#let cell(layers, theta, data: summary, mapping: ranges) = plot(
  data: data,
  mapping: mapping,
  layers: layers,
  coord: coord-radial(theta: theta),
  width: 4.5cm,
  height: 4.5cm,
)

#let col-errorbar-point = (
  geom-col(position: "dodge", alpha: 0.5),
  geom-errorbar(position: "dodge"),
  geom-point(position: "dodge", size: 2pt),
)
#let crossbar-linerange = (
  geom-crossbar(position: "dodge"),
  geom-linerange(mapping: aes(colour: "grp"), position: "dodge"),
)
#let pointrange-line = (
  geom-pointrange(mapping: aes(colour: "grp"), position: "dodge"),
  geom-line(mapping: aes(colour: "grp", group: "grp"), position: "dodge"),
)

#grid(
  columns: 4,
  column-gutter: 0.4cm,
  row-gutter: 0.4cm,
  cell(col-errorbar-point, "x"),
  cell((geom-boxplot(position: "dodge"),), "x", data: raw, mapping: values),
  cell(crossbar-linerange, "x"),
  cell(pointrange-line, "x"),
  cell(col-errorbar-point, "y"),
  cell((geom-boxplot(position: "dodge"),), "y", data: raw, mapping: values),
  cell(crossbar-linerange, "y"),
  cell(pointrange-line, "y"),
)
