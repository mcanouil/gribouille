// Showcase: area chart of unemployment duration with the peak annotated;
// areas keep their zero baseline and the extremum gets named.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(1)

#let peak = economics.sorted(key: row => row.uempmed).last()

#plot(
  data: economics,
  mapping: aes(x: "date", y: "uempmed"),
  layers: (
    geom-area(fill: accent, alpha: 0.35),
    geom-line(stroke: 1.4pt, colour: accent),
    annotate(
      "text",
      x: peak.date,
      y: peak.uempmed,
      label: "peak: " + str(peak.uempmed) + " weeks",
      anchor: "south-east",
      nudge-y: 0.15cm,
      size: 9pt,
    ),
  ),
  scales: scales(
    x: scale-date(date-format: "[year]-[month repr:numerical]"),
    y: scale-continuous(limits: (0, 26)),
  ),
  labels: labels(
    title: "Job searches stretched to half a year by late 2009",
    subtitle: "Median duration of unemployment (weeks), monthly",
    x: "Month",
    y: "Median duration (weeks)",
    caption: "Source: bundled economics dataset (FRED series UEMPMED).",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 7.5cm,
)
