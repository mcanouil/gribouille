// diff-forecast: shade the band between forecast and actuals by which leads.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let series = range(0, 25).map(i => {
  let x = i * 0.5
  (
    week: x,
    forecast: 100 + x * 4,
    actual: 100 + x * 3.6 + calc.sin(x * 0.9) * 12,
  )
})

#plot(
  data: series,
  mapping: aes(x: "week"),
  layers: (
    geom-ribbon(
      mapping: aes(ymin: "forecast", ymax: "actual", fill: after-stat("_sign")),
      stat: stat-difference(levels: ("above forecast", "below forecast")),
      alpha: 0.55,
    ),
    geom-line(mapping: aes(y: "forecast"), stroke: 1.3pt),
    geom-line(mapping: aes(y: "actual"), stroke: 1.3pt, linetype: "dashed"),
  ),
  scales: scales(fill: scale-okabe-ito()),
  labels: labels(
    title: "Sales vs. Forecast",
    subtitle: "Band shaded by whether actuals ran above or below forecast",
    x: "Week",
    y: "Units (thousands)",
    fill: "Actuals vs. forecast",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 7cm,
)
