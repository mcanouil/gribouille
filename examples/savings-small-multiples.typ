// Showcase: three economic series as small multiples with free y scales;
// separate panels beat spaghetti when units and ranges differ.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)

#let series-names = (
  psavert: "Savings rate (%)",
  uempmed: "Unemployment duration (weeks)",
  unemploy: "Unemployed (thousands)",
)

#let long = pivot-longer(
  economics,
  ("psavert", "uempmed", "unemploy"),
  names-to: "series",
  values-to: "value",
).map(row => (..row, series: series-names.at(row.series)))

#plot(
  data: long,
  mapping: aes(x: "date", y: "value"),
  layers: (geom-line(stroke: 1.2pt, colour: accent),),
  scales: scales(x: scale-date(date-format: "[year]-[month repr:numerical]")),
  facet: facet-wrap("series", ncolumn: 3, scales: "free_y"),
  labels: labels(
    title: "The recession in three series",
    subtitle: "Monthly values, 2008-2009; each panel trains its own y axis",
    x: none,
    y: none,
    caption: "Source: bundled economics dataset.",
  ),
  theme: theme-minimal(),
  width: 15cm,
  height: 6.5cm,
)
