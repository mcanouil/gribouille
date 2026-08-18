// waffle: per-group counts turned into unit grid cells via stat-waffle.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let tickets = (
  (status: "Resolved", n: 58),
  (status: "In progress", n: 27),
  (status: "Blocked", n: 9),
  (status: "New", n: 6),
)

#plot(
  data: tickets,
  mapping: aes(fill: "status", weight: "n"),
  layers: (geom-tile(stat: stat-waffle(rows: 10), width: 0.9, height: 0.9),),
  scales: scales(fill: scale-okabe-ito(name: "Status")),
  labels: labels(
    title: "Support Ticket Backlog",
    subtitle: "Each square is one ticket, columns filled from the bottom-left",
    x: none,
    y: none,
  ),
  guides: guides(x: none, y: none),
  theme: theme-void(),
  width: 12cm,
  height: 7cm,
)
