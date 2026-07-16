// Showcase: unemployment time series with an annotated context period and a
// finding stated in the title; annotation does the pointing, not a legend.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)
#let shade = okabe-ito.at(0)

#plot(
  data: economics,
  mapping: aes(x: "date", y: "unemploy"),
  layers: (
    annotate(
      "rect",
      xmin: "2008-09-01",
      xmax: "2009-06-01",
      ymin: 7000,
      ymax: 15500,
      fill: shade.transparentize(80%),
      stroke: none,
    ),
    geom-line(stroke: 1.4pt, colour: accent),
    geom-point(size: 2pt, fill: accent),
    annotate(
      "text",
      x: "2009-01-01",
      y: 14500,
      label: "post-crash surge",
      size: 9pt,
      colour: shade,
    ),
  ),
  scales: scales(
    x: scale-date(date-format: "[year]-[month repr:numerical]"),
    y: scale-continuous(labels: format-comma()),
  ),
  labels: labels(
    title: "Unemployment kept climbing for a year after the 2008 crash",
    subtitle: "Unemployed persons (thousands), monthly, 2008-2009",
    x: "Month",
    y: "Unemployed (thousands)",
    caption: "Source: bundled economics dataset (FRED series UNEMPLOY).",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 8cm,
)
