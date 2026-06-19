// Facet wrap with both axes free: each panel trains its own x and y range.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let zooms = (
  (scale: "near (0-3)", t: 0, v: 1.2),
  (scale: "near (0-3)", t: 1, v: 1.4),
  (scale: "near (0-3)", t: 2, v: 1.5),
  (scale: "near (0-3)", t: 3, v: 1.6),
  (scale: "mid (50-80)", t: 50, v: 30),
  (scale: "mid (50-80)", t: 60, v: 38),
  (scale: "mid (50-80)", t: 70, v: 45),
  (scale: "mid (50-80)", t: 80, v: 52),
  (scale: "far (1000-2500)", t: 1000, v: 600),
  (scale: "far (1000-2500)", t: 1500, v: 720),
  (scale: "far (1000-2500)", t: 2000, v: 880),
  (scale: "far (1000-2500)", t: 2500, v: 950),
)

#plot(
  data: zooms,
  mapping: aes(x: "t", y: "v"),
  layers: (
    geom-line(stroke: 1.2pt, colour: rgb("#1f77b4")),
    geom-point(size: 2.5pt),
  ),
  facet: facet-wrap("scale", ncolumn: 3, scales: "free"),
  labels: labels(
    title: "scales = free trains both x and y per panel",
    subtitle: "Useful when groups span very different domains in both directions",
    x: "Time",
    y: "Value",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
