// weight aesthetic: per-row weights threaded into counts, bins, and smoothers.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#let totals = (
  (region: "North", visitors: 12450),
  (region: "South", visitors: 8200),
  (region: "East", visitors: 14100),
  (region: "West", visitors: 6300),
)

#let bars = plot(
  data: totals,
  mapping: aes(x: "region", weight: "visitors"),
  layers: (geom-bar(fill: accent),),
  scales: scales(y: scale-continuous(labels: format-comma())),
  labels: labels(
    title: "Pre-Aggregated Counts via Weight",
    subtitle: "geom-bar sums the weight column instead of counting rows",
    x: "Region",
    y: "Visitors",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#let pts = ()
#for i in range(0, 20) {
  pts.push((x: i, y: i * 0.5 + calc.sin(i * 0.4), w: 1))
}
// Two outliers with negligible weight: WLS pulls the fit back to the trend.
#pts.push((x: 5, y: 30, w: 0.001))
#pts.push((x: 15, y: -20, w: 0.001))

#let scatter = plot(
  data: pts,
  mapping: aes(x: "x", y: "y", weight: "w"),
  layers: (
    geom-point(size: 2.5pt, alpha: 0.8, colour: accent),
    geom-smooth(method: "lm", colour: accent, fill: accent, alpha: 0.2),
  ),
  labels: labels(
    title: "Weighted Least Squares Ignores Down-Weighted Outliers",
    x: "X",
    y: "Y",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  bars,
  scatter,
)
