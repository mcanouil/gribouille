// Per-geom legend glyphs: line layers contribute strokes, ribbon layers
// contribute filled rectangles, so the `colour` and `fill` aesthetics each
// resolve to the right glyph automatically.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let forecast = (
  (week: 1, fit: 12.0, lo: 10.6, hi: 13.4, band: "95% CI", series: "Baseline"),
  (week: 2, fit: 13.2, lo: 11.8, hi: 14.6, band: "95% CI", series: "Baseline"),
  (week: 3, fit: 13.7, lo: 12.0, hi: 15.4, band: "95% CI", series: "Baseline"),
  (week: 4, fit: 15.1, lo: 13.0, hi: 17.2, band: "95% CI", series: "Baseline"),
  (week: 5, fit: 16.4, lo: 14.0, hi: 18.8, band: "95% CI", series: "Baseline"),
  (week: 6, fit: 17.0, lo: 14.2, hi: 19.8, band: "95% CI", series: "Baseline"),
)

#plot(
  data: forecast,
  mapping: aes(x: "week", y: "fit", colour: "series", fill: "band"),
  layers: (
    geom-ribbon(
      mapping: aes(ymin: "lo", ymax: "hi"),
      alpha: 0.3,
      inherit-aes: true,
    ),
    geom-line(stroke: 1.2pt),
  ),
  scales: scales(x: scale-continuous(name: "Week"), y: scale-continuous(name: "Forecast", labels: format-comma())),
  labels: labels(
    title: "Forecast with Confidence Band",
    subtitle: "Line legend uses a stroke glyph; ribbon legend uses a rectangle",
    colour: "Series",
    fill: "Band",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
