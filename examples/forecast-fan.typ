// Showcase: fan chart with graded 50/80/95% ribbons around a forecast;
// each band is labelled in-plot so the reader knows what the shading means.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)

// Twelve observed months, then a six-month linear extrapolation whose
// uncertainty widens with the horizon.
#let observed = (
  (8.4, 8.9, 9.6, 10.1, 10.7, 11.6, 12.1, 12.6, 13.1, 13.9, 14.3, 14.7)
    .enumerate()
    .map(pair => (month: pair.at(0) + 1, value: pair.at(1)))
)

#let last = observed.last()
#let slope = 0.42
#let forecast = range(0, 7).map(step => {
  let spread = 0.35 * step
  (
    month: last.month + step,
    fit: last.value + slope * step,
    lo50: last.value + slope * step - 0.674 * spread,
    hi50: last.value + slope * step + 0.674 * spread,
    lo80: last.value + slope * step - 1.282 * spread,
    hi80: last.value + slope * step + 1.282 * spread,
    lo95: last.value + slope * step - 1.960 * spread,
    hi95: last.value + slope * step + 1.960 * spread,
  )
})

#plot(
  data: observed,
  mapping: aes(x: "month", y: "value"),
  layers: (
    geom-ribbon(
      inherit-aes: false,
      data: forecast,
      mapping: aes(x: "month", ymin: "lo95", ymax: "hi95"),
      fill: accent,
      alpha: 0.15,
    ),
    geom-ribbon(
      inherit-aes: false,
      data: forecast,
      mapping: aes(x: "month", ymin: "lo80", ymax: "hi80"),
      fill: accent,
      alpha: 0.25,
    ),
    geom-ribbon(
      inherit-aes: false,
      data: forecast,
      mapping: aes(x: "month", ymin: "lo50", ymax: "hi50"),
      fill: accent,
      alpha: 0.4,
    ),
    geom-line(stroke: 1.4pt, colour: accent),
    geom-line(
      inherit-aes: false,
      data: forecast,
      mapping: aes(x: "month", y: "fit"),
      stroke: 1.2pt,
      colour: accent,
      linetype: (4pt, 3pt),
    ),
    annotate(
      "text",
      x: 18.2,
      y: 18.6,
      label: "50%",
      size: 8pt,
      anchor: "west",
      colour: accent,
    ),
    annotate(
      "text",
      x: 18.2,
      y: 19.9,
      label: "80%",
      size: 8pt,
      anchor: "west",
      colour: accent,
    ),
    annotate(
      "text",
      x: 18.2,
      y: 21.3,
      label: "95%",
      size: 8pt,
      anchor: "west",
      colour: accent,
    ),
  ),
  scales: scales(x: scale-continuous(limits: (1, 20))),
  labels: labels(
    title: "The forecast is a range, not a line",
    subtitle: "Observed values (solid), extrapolation (dashed), and 50/80/95% prediction bands",
    x: "Month",
    y: "Index",
    caption: "Synthetic series; band multipliers from the normal quantiles.",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 8cm,
)
