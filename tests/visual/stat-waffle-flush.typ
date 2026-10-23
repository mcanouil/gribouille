// Smoke render: stat-waffle grids sit flush with the panel.
//
// The left panel uses the defaults, so the grid fills the panel with no
// expansion margin and every square is whole. The right panel sets `expand`
// on both position scales, and the margin the user asked for comes back.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (status: "done", n: 14),
  (status: "open", n: 7),
  (status: "new", n: 3),
)

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..(
    scales(),
    scales(
      x: scale-continuous(expand: 15%),
      y: scale-continuous(expand: 15%),
    ),
  ).map(s => plot(
    data: d,
    mapping: aes(fill: "status", weight: "n"),
    layers: (geom-tile(stat: stat-waffle(rows: 4), width: 0.9, height: 0.9),),
    scales: s,
    labels: labels(x: "", y: ""),
    width: 6cm,
    height: 5cm,
  )),
)
