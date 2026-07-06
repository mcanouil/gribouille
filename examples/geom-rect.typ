// geom-rect: filled boxes from xmin/xmax/ymin/ymax.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let releases = (
  (xmin: 2018, xmax: 2019.5, ymin: 0, ymax: 2, version: "v1"),
  (xmin: 2019.5, xmax: 2021, ymin: 0, ymax: 4, version: "v2"),
  (xmin: 2021, xmax: 2023, ymin: 0, ymax: 7, version: "v3"),
  (xmin: 2023, xmax: 2025, ymin: 0, ymax: 11, version: "v4"),
)

#plot(
  data: releases,
  mapping: aes(
    xmin: "xmin",
    xmax: "xmax",
    ymin: "ymin",
    ymax: "ymax",
    fill: "version",
  ),
  layers: (geom-rect(alpha: 0.5, stroke: 0.5pt),),
  scales: scales(x: scale-continuous(breaks: (2018, 2020, 2022, 2024))),
  labels: labels(
    title: "Cumulative Releases per Major Version",
    subtitle: "Each box spans the version's lifetime on the timeline",
    x: "Year",
    y: "Releases Shipped",
    fill: "Version",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
