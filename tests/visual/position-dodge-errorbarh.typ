// Smoke render: geom-errorbarh dodges its groups within each y slot.
//
// The bars run along x, so the dodge slots split the category band on y. Each
// bar stays inside the band of its own category, offset by its group.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (cat: "A", grp: "a", mean: 3, lo: 2, hi: 4),
  (cat: "A", grp: "b", mean: 5, lo: 4, hi: 7),
  (cat: "B", grp: "a", mean: 4, lo: 3, hi: 6),
  (cat: "B", grp: "b", mean: 2, lo: 1, hi: 3),
)

#plot(
  data: d,
  mapping: aes(y: "cat", x: "mean", xmin: "lo", xmax: "hi", colour: "grp"),
  layers: (geom-errorbarh(position: "dodge"),),
  width: 8cm,
  height: 6cm,
)
