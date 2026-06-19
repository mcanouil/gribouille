// `after-stat` binds an aesthetic to a column produced by the layer's
// stat. `geom-bar` runs `stat-count`, publishing `_count` per category;
// here we bind y to that column by name to make the contract explicit
// rather than relying on the geom's implicit y default. With no `labels(y:)`
// override, the y-axis title is derived from the marker: `_count` -> `Count`.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (grp: "a"),
  (grp: "b"),
  (grp: "a"),
  (grp: "c"),
  (grp: "a"),
  (grp: "b"),
  (grp: "d"),
  (grp: "a"),
)

#plot(
  data: d,
  mapping: aes(
    x: "grp",
    y: after-stat("_count"),
    fill: "grp",
  ),
  layers: (geom-bar(),),
  guides: guides(fill: none),
  labels: labels(
    title: "Explicit After-Stat Binding",
    x: "Group",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
