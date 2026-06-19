// geom-step: stair-step interpolation between consecutive points.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let releases = (
  (version: 1, year: 2018, users: 120),
  (version: 2, year: 2019, users: 220),
  (version: 3, year: 2020, users: 360),
  (version: 4, year: 2021, users: 410),
  (version: 5, year: 2022, users: 580),
  (version: 6, year: 2023, users: 760),
  (version: 7, year: 2024, users: 940),
)

#plot(
  data: releases,
  mapping: aes(x: "year", y: "users"),
  layers: (
    geom-step(stroke: 1.2pt, direction: "hv", colour: rgb("#1f77b4")),
    geom-point(size: 3pt, fill: rgb("#1f77b4")),
  ),
  scales: (
    scale-x-continuous(breaks: (2018, 2020, 2022, 2024)),
    scale-y-continuous(labels: format-comma()),
  ),
  labels: labels(
    title: "Active Users at Each Release",
    subtitle: "Step interpolation reflects discrete release events",
    x: "Year",
    y: "Active Users",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
