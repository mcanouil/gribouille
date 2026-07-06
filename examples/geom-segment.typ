// geom-segment: straight lines from (x, y) to (xend, yend).

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let changes = (
  (
    team: "Engineering",
    year-start: 2020,
    headcount-start: 14,
    year-end: 2024,
    headcount-end: 38,
  ),
  (
    team: "Design",
    year-start: 2020,
    headcount-start: 4,
    year-end: 2024,
    headcount-end: 11,
  ),
  (
    team: "Product",
    year-start: 2020,
    headcount-start: 6,
    year-end: 2024,
    headcount-end: 18,
  ),
  (
    team: "Sales",
    year-start: 2020,
    headcount-start: 8,
    year-end: 2024,
    headcount-end: 22,
  ),
)

#plot(
  data: changes,
  mapping: aes(
    x: "year-start",
    y: "headcount-start",
    xend: "year-end",
    yend: "headcount-end",
    colour: "team",
  ),
  layers: (
    geom-segment(stroke: 1.4pt),
    geom-point(size: 3pt),
  ),
  scales: scales(x: scale-continuous(breaks: (2020, 2022, 2024))),
  labels: labels(
    title: "Team Headcount, 2020 To 2024",
    subtitle: "Each segment connects start and end values per team",
    x: "Year",
    y: "Headcount",
    colour: "Team",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
